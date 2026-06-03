import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/find_care/presentation/providers/cms_provider_favorites_provider.dart';
import 'package:flutter_template/features/find_care/presentation/providers/provider_favorites_provider.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/data/home_saved_providers_builder.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

class SavedProvidersScreen extends ConsumerWidget {
  const SavedProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = buildHomeSavedProviders(
      mockFavoriteIds: ref.watch(providerFavoritesProvider),
      cmsFavorites: ref.watch(cmsProviderFavoritesProvider),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(title: 'Saved Providers', showBack: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (providers.isEmpty)
                  _SavedProvidersEmptyState(
                    onFindCare: () =>
                        context.pushNamed(AppRouter.findCare.toPathName),
                  )
                else
                  ...providers.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SavedProviderCard(
                        item: item,
                        onTap: () => _openProvider(context, item),
                        onRemove: () => _removeProvider(context, ref, item),
                        onCall: item.phone == null
                            ? null
                            : () => _launchTel(context, item.phone!),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openProvider(BuildContext context, SavedProviderItem item) {
    if (item.kind == HomeSavedProviderKind.cms) {
      final npi = item.medicareNpi;
      if (npi == null) return;
      context.pushNamed(
        AppRouter.medicareProviderDetailName,
        pathParameters: {'npi': npi},
      );
      return;
    }

    final id = item.providerId ?? item.key.replaceFirst('m-', '');
    context.pushNamed(
      AppRouter.providerDetailName,
      pathParameters: {'id': id},
    );
  }

  void _removeProvider(
    BuildContext context,
    WidgetRef ref,
    SavedProviderItem item,
  ) {
    if (item.kind == HomeSavedProviderKind.cms) {
      final npi = item.medicareNpi;
      if (npi != null) {
        ref.read(cmsProviderFavoritesProvider.notifier).remove(npi);
      }
    } else {
      final id = item.providerId ?? item.key.replaceFirst('m-', '');
      ref.read(providerFavoritesProvider.notifier).toggle(id);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Provider removed: ${item.name}')),
      );
  }

  Future<void> _launchTel(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final launched = await launchUrlString('tel:$digits');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }
}

class _SavedProvidersEmptyState extends StatelessWidget {
  const _SavedProvidersEmptyState({required this.onFindCare});

  final VoidCallback onFindCare;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: vcare.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(LucideIcons.heart, color: vcare.accent, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Save your go-to providers',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep the places you and your family rely on — Urgent Care, ER, '
            'Pharmacy, PCP and more — one tap away when you need them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onFindCare,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text('Go to providers'),
          ),
        ],
      ),
    );
  }
}

class _SavedProviderCard extends StatelessWidget {
  const _SavedProviderCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
    this.onCall,
  });

  final SavedProviderItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: vcare.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: vcare.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 52, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.tag.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: VCareColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.rating != null) ...[
                        Icon(LucideIcons.star, size: 14, color: vcare.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color: vcare.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: vcare.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (onCall != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CallChip(onTap: onCall!),
                        const SizedBox(width: 8),
                        _NetworkChip(inNetwork: item.inNetwork),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            onPressed: onRemove,
            tooltip: 'Remove from favorites',
            style: IconButton.styleFrom(
              backgroundColor: vcare.card.withValues(alpha: 0.9),
              side: BorderSide(color: vcare.border),
              minimumSize: const Size(36, 36),
            ),
            icon: Icon(
              LucideIcons.heart,
              size: 18,
              color: VCareColors.destructive,
              fill: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _CallChip extends StatelessWidget {
  const _CallChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VCareColors.primary.withValues(alpha: 0.1),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.phone, size: 12, color: VCareColors.primary),
              const SizedBox(width: 4),
              Text(
                'Call',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VCareColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.inNetwork});

  final bool inNetwork;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: inNetwork
            ? VCareColors.primary.withValues(alpha: 0.1)
            : vcare.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        inNetwork ? 'In-network' : 'Out-of-network',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: inNetwork ? VCareColors.primary : vcare.mutedForeground,
        ),
      ),
    );
  }
}
