import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_empty_state_card.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_horizontal_carousel.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_saved_provider_card.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_section_header.dart';

class HomeSavedProvidersSection extends StatelessWidget {
  const HomeSavedProvidersSection({
    super.key,
    required this.providers,
    this.onSeeAll,
    this.onFindCare,
    this.onProviderTap,
    this.onRemove,
    this.isRemoving,
  });

  final List<SavedProviderItem> providers;
  final VoidCallback? onSeeAll;
  final VoidCallback? onFindCare;
  final void Function(SavedProviderItem item)? onProviderTap;
  final void Function(SavedProviderItem item)? onRemove;
  final bool Function(SavedProviderItem item)? isRemoving;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Saved Providers',
          seeAllLabel: providers.isNotEmpty ? 'See all' : null,
          onSeeAll: onSeeAll,
        ),
        if (providers.isEmpty)
          HomeEmptyStateCard(
            icon: LucideIcons.heart,
            title: 'Save your go-to providers',
            description:
                'Urgent Care, ER, Pharmacy and more — one tap away for you and your family.',
            ctaLabel: 'Find providers',
            onTap: onFindCare,
            iconColor: vcare.accent,
            iconBackgroundColor: vcare.accent.withValues(alpha: 0.1),
          )
        else
          HomeHorizontalCarouselSized(
            height: 112,
            itemCount: providers.length > 6 ? 6 : providers.length,
            itemWidth: 260,
            itemBuilder: (context, index) {
              final p = providers[index];
              return HomeSavedProviderCard(
                item: p,
                onTap: () => onProviderTap?.call(p),
                onRemove: () => onRemove?.call(p),
                isRemoving: isRemoving?.call(p) ?? false,
              );
            },
          ),
      ],
    );
  }
}
