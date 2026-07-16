import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/main_wrapper/domain/enums/nav_item.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_insets.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_scope.dart';

export 'package:vcare_admin/shared/layout/vcare_mobile_shell_insets.dart';

/// Returns 0 when [MainWrapperScreen] already applied shell bottom inset.
double vcareTabComposerBottomPadding(BuildContext context) {
  if (VCareMobileShellScope.appliesBottomInsetOf(context)) {
    return 0;
  }
  return vcareMobileBottomNavContentPadding(context);
}

const double _pillPaddingH = 4; // px-1
const double _sideIconWellWidth = 40; // w-10
const double _homeFabSize = VCareLayout.bottomNavHomeFabSize;
const double _homeFabLift = 28; // -mt-7
const double _homeFabRing = 4; // ring-4 (outside the 52px circle)
const double _homeLabelGap = 6; // gap-0.5 + mt-1
const double _homeActiveScale = 1.05;
const double _homeFabVisualSize = _homeFabSize + _homeFabRing * 2;

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

    if (width >= VCareLayout.mobileBreakpoint) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: vcareMobileBottomNavHeight(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          VCareMobileShellInsets.navOuterHorizontal,
          0,
          VCareMobileShellInsets.navOuterHorizontal,
          bottom + VCareMobileShellInsets.navOuterBottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: VCareLayout.bottomNavMaxWidth,
            ),
            child: SizedBox(
              height: VCareMobileShellInsets.barBodyHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: VCareMobileShellInsets.pillHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          VCareLayout.bottomNavPillRadius,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                VCareColors.foreground.withValues(alpha: 0.18),
                            offset: const Offset(0, 10),
                            blurRadius: 30,
                            spreadRadius: -12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          VCareLayout.bottomNavPillRadius,
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: vcare.card.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(
                                VCareLayout.bottomNavPillRadius,
                              ),
                              border: Border.all(color: vcare.border),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _pillPaddingH,
                    right: _pillPaddingH,
                    bottom: VCareMobileShellInsets.pillPaddingV,
                    top: VCareMobileShellInsets.navOuterTop +
                        VCareMobileShellInsets.pillPaddingV,
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

  static final _homeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      VCareColors.primary,
      VCareColors.primary.withValues(alpha: 0.8),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final color = isActive ? VCareColors.primary : vcare.mutedForeground;

    if (item.isCenter) {
      // Web: 52px circle with -mt-7 (28). Layout height becomes 24; overflow sits
      // above the pill. Label uses mt-1. Align bottom so no flex gap lifts the FAB.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: VCareMobileShellInsets.tabVerticalPadding,
              horizontal: 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  // CSS -mt-7 on a 52px element → 24px layout height.
                  height: _homeFabSize - _homeFabLift,
                  width: _homeFabVisualSize,
                  child: OverflowBox(
                    minHeight: _homeFabSize,
                    maxHeight: _homeFabSize,
                    minWidth: _homeFabVisualSize,
                    maxWidth: _homeFabVisualSize,
                    alignment: Alignment.bottomCenter,
                    child: AnimatedScale(
                      scale: isActive ? _homeActiveScale : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: _homeFabSize,
                        height: _homeFabSize,
                        decoration: BoxDecoration(
                          gradient: _homeGradient,
                          shape: BoxShape.circle,
                          // ring-4 is outside the box (not an inset Border).
                          boxShadow: [
                            BoxShadow(
                              color: vcare.card,
                              spreadRadius: _homeFabRing,
                              blurRadius: 0,
                            ),
                            BoxShadow(
                              color:
                                  VCareColors.primary.withValues(alpha: 0.55),
                              offset: const Offset(0, 10),
                              blurRadius: 24,
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: Icon(
                          item.icon,
                          color: VCareColors.primaryForeground,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: _homeLabelGap),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: VCareMobileShellInsets.tabLabelSize,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: VCareMobileShellInsets.tabVerticalPadding,
          horizontal: 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _sideIconWellWidth,
              height: VCareMobileShellInsets.sideIconWellHeight,
              decoration: BoxDecoration(
                color: isActive
                    ? VCareColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedScale(
                scale: isActive ? 1.1 : 1,
                duration: const Duration(milliseconds: 200),
                child: Icon(item.icon, size: 18, color: color),
              ),
            ),
            const SizedBox(height: VCareMobileShellInsets.tabIconLabelGap),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: VCareMobileShellInsets.tabLabelSize,
                fontWeight: FontWeight.w500,
                height: 1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
