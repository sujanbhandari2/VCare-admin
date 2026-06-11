import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/cms_provider_favorites_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/provider_favorites_provider.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/data/home_saved_providers_builder.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_saved_provider_card.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

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
                      child: SavedProviderListCard(
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
    context.pushNamed(AppRouter.providerDetailName, pathParameters: {'id': id});
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
      ..showSnackBar(SnackBar(content: Text('Provider removed: ${item.name}')));
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
