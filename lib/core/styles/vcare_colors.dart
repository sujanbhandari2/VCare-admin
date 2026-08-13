import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_hsl.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';

/// Default VCare design tokens — parity with
/// `ui-vcare-admin-console/src/index.css` light mode + DEFAULT_BRANDING.
///
/// Prefer [Theme.of] / `context.vcare` at runtime so tenant branding applies.
/// These static values are the web defaults and fallbacks.
class VCareColors {
  VCareColors._();

  static Color _hsl(double h, double s, double l) =>
      VCareHsl.colorFromHsl(h, s, l);

  // —— Semantic (web light) ——
  static final background = _hsl(30, 50, 98);
  static final foreground = _hsl(200, 50, 12);

  static final card = _hsl(30, 20, 95);
  static final cardForeground = foreground;

  static final primary = _hsl(17, 75, 52);
  static final primaryForeground = Colors.white;

  static final secondary = _hsl(183, 47, 32);
  static final secondaryForeground = Colors.white;

  static final muted = _hsl(30, 20, 94);
  static final mutedForeground = _hsl(200, 15, 40);

  static final accent = _hsl(30, 20, 92);
  static final accentForeground = foreground;

  static final success = _hsl(145, 63, 38);
  static final successForeground = Colors.white;

  static final warning = _hsl(38, 92, 50);
  static final warningForeground = _hsl(210, 22, 10);

  static final info = _hsl(205, 80, 45);
  static final infoForeground = Colors.white;

  static final destructive = _hsl(4, 64, 48);
  static final destructiveForeground = Colors.white;

  static final border = _hsl(28, 24, 88);
  static final input = _hsl(30, 25, 88);
  static final ring = _hsl(17, 80, 56);

  /// Soft primary tint — replaces legacy tealLight.
  static final tealLight = _hsl(183, 35, 97);

  /// Soft secondary/warm tint — replaces legacy terracottaLight.
  static final terracottaLight = _hsl(17, 85, 94);

  /// Common one-off surfaces used across web console.
  static const filterPanel = Color(0xFFF3F5F6);
  static const tableHeader = Color(0xFFF2F0EC);
  static const sectionSurface = Color(0xFFFCFCF8);

  /// Login card surface.
  static const loginCardSurface = Color(0xFFFBFBFC);

  /// Default brand hex values (web DEFAULT_BRANDING).
  static const defaultPrimaryHex = '#e06629';
  static const defaultSecondaryHex = '#2f7f79';
  static const defaultAccentHex = '#f3f0ed';

  /// Default radius (web `--radius` = 8px / md). Prefer [VCareRadius].
  static const radius = VCareRadius.xl;

  /// Fixed brand teal for list card surfaces. Intentionally not tenant-branded
  /// so case/client cards stay consistent across tenants.
  static const cardTintBase = Color(0xFF009B9E);
  static const cardTintBorder = Color(0xFFEEEFF2);

  /// Fixed brand teal for the failed-payment recovery CTAs. Web hardcodes
  /// these hexes instead of the tenant brand, and picks hover/active by hand
  /// rather than from the generated 600/700 scale steps.
  static const paymentRecoveryCta = Color(0xFF009B9D);
  static const paymentRecoveryCtaHover = Color(0xFF008789);
  static const paymentRecoveryCtaActive = Color(0xFF007678);

  static LinearGradient get cardTint => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cardTintBase.withValues(alpha: 0.15),
      cardTintBase.withValues(alpha: 0.05),
    ],
  );

  static LinearGradient get primaryTint => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
  );

  static LinearGradient get gradientHero => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondary.withValues(alpha: 0.85)],
  );

  static LinearGradient get gradientTeal => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, _hsl(183, 38, 45)],
  );

  static LinearGradient get gradientCard => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, _hsl(183, 50, 22)],
  );

  static LinearGradient get gradientWarm => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_hsl(30, 40, 97), _hsl(30, 25, 94)],
  );

  static LinearGradient get gradientSunset => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );

  static LinearGradient get gradientAction => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, _hsl(17, 75, 58)],
  );

  static LinearGradient get gradientCardDark => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_hsl(183, 50, 35), secondary],
  );
}

/// Mobile layout metrics shared across shell widgets.
abstract final class VCareLayout {
  static const pageHorizontalPadding = VCareSpacing.s5;
  static const cardRadius2xl = VCareRadius.xl;
  static const cardRadius3xl = VCareRadius.xxl;
  static const loginCardRadius = 32.0;
  static const sheetTopRadius = VCareRadius.xxl;
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
