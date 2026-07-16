import 'package:flutter/material.dart';

/// VCare design.tokens — parity: vcare-agent-app-2.0/src/index.css
class VCareColors {
  VCareColors._();

  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1, h, s / 100, l / 100).toColor();

  static final background = _hsl(0, 0, 100);
  static final foreground = _hsl(181, 47, 17);

  static final card = _hsl(220, 16, 98.5);
  static final cardForeground = foreground;

  static final primary = _hsl(181, 100, 31);
  static final primaryForeground = Colors.white;

  static final secondary = _hsl(20, 82, 55);
  static final secondaryForeground = Colors.white;

  static final muted = _hsl(220, 14, 95);
  static final mutedForeground = _hsl(181, 25, 32);

  static final accent = _hsl(20, 82, 55);
  static final accentForeground = Colors.white;

  static final success = _hsl(160, 60, 40);
  static final successForeground = Colors.white;

  static final destructive = _hsl(0, 70, 55);
  static final destructiveForeground = Colors.white;

  static final border = _hsl(220, 13, 94);

  static final tealLight = _hsl(181, 30, 95);
  static final terracottaLight = _hsl(20, 60, 96);

  /// Login card surface — web LoginShell inline `#fbfbfc`.
  static const loginCardSurface = Color(0xFFFBFBFC);

  static const radius = 16.0;

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7A73), Color(0xFF3F8F87)],
  );

  static const gradientTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7A73), Color(0xFF3D9494)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF009E9E), Color(0xFF0B6B6B)],
  );

  static const gradientWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F3EE), Color(0xFFF0EBE5)],
  );

  static const gradientSunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F9494), Color(0xFFD97A4A)],
  );

  static const gradientAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE06A2E), Color(0xFFE07A3A)],
  );

  static const gradientCardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B3B3), Color(0xFF0D7A7A)],
  );
}

/// Mobile layout metrics shared across shell widgets.
abstract final class VCareLayout {
  static const pageHorizontalPadding = 20.0;
  static const cardRadius2xl = 16.0;
  static const cardRadius3xl = 24.0;
  static const loginCardRadius = 32.0;
  static const sheetTopRadius = 24.0;
  static const bottomNavMaxWidth = 480.0;
  static const bottomNavHomeFabSize = 52.0;
  static const bottomNavPillRadius = 26.0;
  static const mobileBottomNavContentGap = 4.0;
  /// Scroll/content bottom clearance above the floating nav on Android phones.
  static const mobileBottomNavContentPaddingAndroid = 90.0;
  /// Scroll/content bottom clearance above the floating nav on iPhones.
  static const mobileBottomNavContentPaddingIos = 105.0;
  static const mobileBreakpoint = 768.0;
}
