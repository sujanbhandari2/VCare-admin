import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/main_wrapper/domain/enums/nav_item.dart';

const double _barBodyHeight = 104;
const double _pillHeight = 78;
const double _homeFabSize = 62;

/// How far the center Home FAB sits above the pill top (¼ of button height).
const double _homeFabProtrusion = _homeFabSize / 4;
const double _homeFabTop = _barBodyHeight - _pillHeight - _homeFabProtrusion;

const double _bottomNavOuterPadding = 8;

/// Total height of the floating mobile bottom nav, including safe-area inset.
double vcareMobileBottomNavHeight(BuildContext context) {
  if (MediaQuery.sizeOf(context).width >= 768) return 0;
  return _barBodyHeight +
      _bottomNavOuterPadding +
      MediaQuery.paddingOf(context).bottom;
}

/// Distance from the screen bottom to the top edge of the nav pill.
double vcareMobileBottomNavBarTop(BuildContext context) {
  if (MediaQuery.sizeOf(context).width >= 768) return 0;
  return MediaQuery.paddingOf(context).bottom +
      _bottomNavOuterPadding +
      _pillHeight;
}

/// Bottom padding to pin content [gap] px above the nav pill.
double vcareMobileBottomNavContentPadding(
  BuildContext context, {
  double gap = 10,
}) {
  final pillTop = vcareMobileBottomNavBarTop(context);
  if (pillTop == 0) return 12;
  return pillTop + gap;
}

/// Mobile bottom nav matching vcareapp [MobileShell] (Home centered, floating pill).
class VcareBottomNavigation extends StatelessWidget {
  const VcareBottomNavigation({
    super.key,
    required this.currentItem,
    required this.onSelect,
  });

  final NavItem currentItem;
  final ValueChanged<NavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 768) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: vcareMobileBottomNavHeight(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + _bottomNavOuterPadding),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: _barBodyHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _pillHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: vcare.card.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: vcare.border),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 8,
                      height: 96,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: NavItem.mobileTabs.map((item) {
                          final isActive = item == currentItem;
                          return Expanded(
                            child: _NavTab(
                              item: item,
                              isActive: isActive,
                              vcare: vcare,
                              onTap: () => onSelect(item),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.isActive,
    required this.vcare,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final VCareThemeExtension vcare;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? VCareColors.primary : vcare.mutedForeground;

    if (item.isCenter) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 96,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                top: _homeFabTop,
                child: AnimatedScale(
                  scale: isActive ? 1.04 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: _homeFabSize,
                    height: _homeFabSize,
                    decoration: BoxDecoration(
                      gradient: vcare.gradientCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: vcare.card, width: 5),
                    ),
                    child: Icon(
                      item.icon,
                      color: VCareColors.primaryForeground,
                      size: 25,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? VCareColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 18, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
