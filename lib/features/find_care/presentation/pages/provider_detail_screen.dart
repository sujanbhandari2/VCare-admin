import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/find_care/data/find_care_mock_data.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/provider_favorites_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/widgets/provider_detail_info_row.dart';
import 'package:vcare_admin/features/home/data/home_models.dart'
    as home_models;
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

/// Layout tokens from vcareapp `ProviderDetailBody` (`px-5`, `space-y-5`, etc.).
abstract final class ProviderDetailLayout {
  static const double horizontalPadding = 20;
  static const double sectionGap = 20;
  static const double heroRadius = 24;
  static const double cardRadius = 24;
  static const double actionRadius = 16;
  static const Color tealLight = Color(0xFFE8F4F4);
}

class ProviderDetailScreen extends ConsumerWidget {
  const ProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = FindCareMockData.providerById(providerId);
    final vcare = context.vcare;

    if (provider == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: VcarePageHeader(title: 'Provider', showBack: true),
            ),
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProviderDetailLayout.horizontalPadding,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Provider not found.',
                    style: TextStyle(color: vcare.mutedForeground),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isFavorite = ref
        .watch(providerFavoritesProvider)
        .contains(provider.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(title: 'Provider', showBack: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              ProviderDetailLayout.horizontalPadding,
              0,
              ProviderDetailLayout.horizontalPadding,
              40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProviderHeroCard(
                  provider: provider,
                  isFavorite: isFavorite,
                  onToggleFavorite: () {
                    final saved = ref
                        .read(providerFavoritesProvider.notifier)
                        .toggle(provider.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            saved
                                ? 'Provider saved: ${provider.name}'
                                : 'Provider removed: ${provider.name}',
                          ),
                        ),
                      );
                  },
                ),
                const SizedBox(height: ProviderDetailLayout.sectionGap),
                _ProviderDetailsCard(
                  provider: provider,
                  onCall: () => _launchTel(context, provider.phone),
                ),
                const SizedBox(height: ProviderDetailLayout.sectionGap),
                _ProviderActionButtons(
                  onCall: () => _launchTel(context, provider.phone),
                  onDirections: () => _launchDirections(context, provider),
                ),
                const SizedBox(height: ProviderDetailLayout.sectionGap),
                const _BookingHelpBanner(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchTel(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final launched = await launchUrlString('tel:$digits');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phone')));
    }
  }

  static Future<void> _launchDirections(
    BuildContext context,
    home_models.Provider provider,
  ) async {
    final query = Uri.encodeComponent(provider.fullAddress);
    final launched = await launchUrlString(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }
}

class _ProviderHeroCard extends StatelessWidget {
  const _ProviderHeroCard({
    required this.provider,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final home_models.Provider provider;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(ProviderDetailLayout.heroRadius),
        border: Border.all(color: vcare.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.specialty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: VCareColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.star, size: 16, color: vcare.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ' · ${provider.distanceMi} mi away',
                      style: TextStyle(
                        fontSize: 14,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFavorite,
            tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
            style: IconButton.styleFrom(
              backgroundColor: vcare.card.withValues(alpha: 0.9),
              side: BorderSide(color: vcare.border),
              minimumSize: const Size(40, 40),
            ),
            icon: Icon(
              LucideIcons.heart,
              size: 20,
              color: isFavorite
                  ? VCareColors.destructive
                  : vcare.mutedForeground,
              fill: isFavorite ? 1.0 : 0.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderDetailsCard extends StatelessWidget {
  const _ProviderDetailsCard({required this.provider, required this.onCall});

  final home_models.Provider provider;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(ProviderDetailLayout.cardRadius),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        children: [
          ProviderDetailInfoRow(
            icon: LucideIcons.mapPin,
            label: 'Address',
            value: provider.fullAddress,
          ),
          Divider(height: 1, color: vcare.border),
          ProviderDetailInfoRow(
            icon: LucideIcons.phone,
            label: 'Phone',
            value: provider.phone,
            onTap: onCall,
          ),
          Divider(height: 1, color: vcare.border),
          ProviderDetailInfoRow(
            icon: LucideIcons.clock,
            label: 'Hours',
            value: provider.hours,
          ),
        ],
      ),
    );
  }
}

class _ProviderActionButtons extends StatelessWidget {
  const _ProviderActionButtons({
    required this.onCall,
    required this.onDirections,
  });

  final VoidCallback onCall;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onCall,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ProviderDetailLayout.actionRadius,
                ),
              ),
            ),
            child: const Text(
              'Call now',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: onDirections,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: vcare.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ProviderDetailLayout.actionRadius,
                ),
              ),
            ),
            child: const Text(
              'Get directions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingHelpBanner extends StatelessWidget {
  const _BookingHelpBanner();

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProviderDetailLayout.tealLight,
        borderRadius: BorderRadius.circular(ProviderDetailLayout.actionRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need help booking?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Your advocate can call ahead, verify benefits, and schedule for you.',
            style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
          ),
        ],
      ),
    );
  }
}
