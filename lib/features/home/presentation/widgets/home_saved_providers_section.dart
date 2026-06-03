import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_empty_state_card.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_horizontal_carousel.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_section_header.dart';

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
            height: 100,
            itemCount: items.length > 6 ? 6 : items.length,
            itemWidth: 260,
            itemBuilder: (context, index) {
              final p = items[index];
              return _SavedProviderCard(
                item: p,
                vcare: vcare,
                onTap: () => onProviderTap?.call(p),
                onRemove: () => onRemove?.call(p),
              );
            },
          ),
      ],
    );
  }
}

class _SavedProviderCard extends StatelessWidget {
  const _SavedProviderCard({
    required this.item,
    required this.vcare,
    this.onTap,
    this.onRemove,
  });

  final SavedProviderItem item;
  final VCareThemeExtension vcare;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.kind == HomeSavedProviderKind.mock &&
                          item.rating != null) ...[
                        Icon(LucideIcons.star, size: 12, color: vcare.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${item.rating}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: vcare.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: VCareColors.background.withValues(alpha: 0.8),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: vcare.border),
                ),
                child: Icon(
                  LucideIcons.heart,
                  size: 14,
                  color: VCareColors.destructive,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
