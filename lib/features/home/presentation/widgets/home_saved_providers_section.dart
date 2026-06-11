import 'package:flutter/foundation.dart';
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
    this.previewEmpty = false,
    this.onPreviewToggle,
    this.onSeeAll,
    this.onFindCare,
    this.onProviderTap,
    this.onRemove,
  });

  final List<SavedProviderItem> providers;
  final bool previewEmpty;
  final VoidCallback? onPreviewToggle;
  final VoidCallback? onSeeAll;
  final VoidCallback? onFindCare;
  final void Function(SavedProviderItem item)? onProviderTap;
  final void Function(SavedProviderItem item)? onRemove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final items = previewEmpty ? <SavedProviderItem>[] : providers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Saved Providers',
          seeAllLabel: items.isNotEmpty ? 'See all' : null,
          onSeeAll: onSeeAll,
          showPreviewToggle: kDebugMode,
          previewEmpty: previewEmpty,
          onPreviewToggle: onPreviewToggle,
        ),
        if (items.isEmpty)
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
            itemCount: items.length > 6 ? 6 : items.length,
            itemWidth: 260,
            itemBuilder: (context, index) {
              final p = items[index];
              return HomeSavedProviderCard(
                item: p,
                onTap: () => onProviderTap?.call(p),
                onRemove: () => onRemove?.call(p),
              );
            },
          ),
      ],
    );
  }
}
