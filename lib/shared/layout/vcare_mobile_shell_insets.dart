import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/features/main_wrapper/domain/enums/nav_item.dart';

/// Mirrors vcareapp [MobileShell] mobile bottom nav metrics (Tailwind → logical px).
abstract final class VCareMobileShellInsets {
  static const navOuterHorizontal = 8.0; // px-2
  static const navOuterBottom = 8.0; // pb-2
  static const navOuterTop = 24.0; // pt-6 — room for raised Home above the pill
  static const pillPaddingV = 6.0; // pt/pb-1.5
  static const tabVerticalPadding = 4.0; // py-1
  static const tabIconLabelGap = 2.0; // gap-0.5
  static const sideIconWellHeight = 32.0; // h-8
  static const tabLabelSize = 10.0; // text-[10px]

  /// Pill height from non-center tab chrome (center Home overflows above the pill).
  static const pillHeight = pillPaddingV * 2 +
      tabVerticalPadding * 2 +
      sideIconWellHeight +
      tabIconLabelGap +
      tabLabelSize;

  /// Bar body = top overflow room + pill (matches nav `pt-6` + pill).
  static const barBodyHeight = navOuterTop + pillHeight;

  /// Padding when bottom nav is hidden (tablet / non-tab routes).
  static const fallbackContentPadding = 12.0;
}

/// Whether the floating mobile bottom nav is shown for the current route.
bool isMobileBottomNavVisible(BuildContext context) {
  if (MediaQuery.sizeOf(context).width >= VCareLayout.mobileBreakpoint) {
    return false;
  }
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    return true;
  }
  final matchedLocation = router.state.matchedLocation;
  return NavItem.mobileTabs.any(
    (item) => matchedLocation.startsWith(item.path),
  );
}

/// Total height of the floating mobile bottom nav, including safe-area inset.
double vcareMobileBottomNavHeight(BuildContext context) {
  if (!isMobileBottomNavVisible(context)) {
    return 0;
  }
  return VCareMobileShellInsets.barBodyHeight +
      VCareMobileShellInsets.navOuterBottom +
      MediaQuery.paddingOf(context).bottom;
}

/// Distance from the screen bottom to the top edge of the nav pill.
double vcareMobileBottomNavBarTop(BuildContext context) {
  if (!isMobileBottomNavVisible(context)) {
    return 0;
  }
  return MediaQuery.paddingOf(context).bottom +
      VCareMobileShellInsets.navOuterBottom +
      VCareMobileShellInsets.pillHeight;
}

/// Bottom padding so scrollable content clears the floating mobile bottom nav.
double vcareMobileBottomNavContentPadding(BuildContext context) {
  if (!isMobileBottomNavVisible(context)) {
    return VCareMobileShellInsets.fallbackContentPadding;
  }
  return _mobileShellContentPaddingForPlatform(context);
}

bool _isIosContentPaddingPlatform(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
      return true;
    case TargetPlatform.android:
      return false;
    default:
      // Web/desktop tests: treat home-indicator safe area as iPhone-like.
      return MediaQuery.paddingOf(context).bottom >= 20;
  }
}

double _mobileShellContentPaddingForPlatform(BuildContext context) {
  if (_isIosContentPaddingPlatform(context)) {
    return VCareLayout.mobileBottomNavContentPaddingIos;
  }
  return VCareLayout.mobileBottomNavContentPaddingAndroid;
}
