import "package:flutter/material.dart";

import "vcare_theme.dart";

/// App theme using VCare design tokens (vcareapp/src/index.css).
class AppTheme {
  AppTheme._();

  static ThemeData light({
    Color? seedColor,
    DynamicSchemeVariant dynamicSchemeVariant = DynamicSchemeVariant.fidelity,
    double contrastLevel = 0.0,
  }) {
    return VCareTheme.light(contrastLevel: contrastLevel);
  }

  static ThemeData dark({
    Color? seedColor,
    DynamicSchemeVariant dynamicSchemeVariant = DynamicSchemeVariant.fidelity,
    double contrastLevel = 0.0,
  }) {
    return VCareTheme.dark(contrastLevel: contrastLevel);
  }
}

/// Extension functions [TextThemeExt] on TextTheme
///
/// Now you can use context.textTheme.regular12 and so on
///
/// TextThemeExt
extension TextThemeExt on TextTheme {
  // Private method to create regular text style
  TextStyle? _regular(double size) => TextStyle(
    fontSize: size,
    fontFamily: bodyLarge?.fontFamily,
    fontWeight: FontWeight.w400,
    color: bodyLarge?.color,
  );

  // Private method to create medium text style
  TextStyle? _medium(double size) => TextStyle(
    fontSize: size,
    fontFamily: bodyLarge?.fontFamily,
    fontWeight: FontWeight.w500,
    color: labelLarge?.color,
  );

  // Private method to create bold text style
  TextStyle? _semibold(double size) => TextStyle(
    fontSize: size,
    fontFamily: bodyLarge?.fontFamily,
    fontWeight: FontWeight.w600,
    color: titleLarge?.color,
  );

  // Private method to create bold text style
  TextStyle? _bold(double size) => TextStyle(
    fontSize: size,
    fontFamily: bodyLarge?.fontFamily,
    fontWeight: FontWeight.w700,
    color: titleLarge?.color,
  );

  // Regular Styles
  TextStyle? get regular8 => _regular(8.0);

  TextStyle? get regular10 => _regular(10.0);

  TextStyle? get regular12 => _regular(12.0);

  TextStyle? get regular14 => _regular(14.0);

  TextStyle? get regular16 => _regular(16.0);

  TextStyle? get regular18 => _regular(18.0);

  TextStyle? get regular20 => _regular(20.0);

  TextStyle? get regular22 => _regular(22.0);

  TextStyle? get regular24 => _regular(24.0);

  TextStyle? get regular28 => _regular(28.0);

  TextStyle? get regular32 => _regular(32.0);

  TextStyle? get regular36 => _regular(36.0);

  TextStyle? get regular42 => _regular(42.0);

  TextStyle? get regular48 => _regular(48.0);

  // Medium Styles
  TextStyle? get medium8 => _medium(8.0);

  TextStyle? get medium10 => _medium(10.0);

  TextStyle? get medium12 => _medium(12.0);

  TextStyle? get medium14 => _medium(14.0);

  TextStyle? get medium16 => _medium(16.0);

  TextStyle? get medium18 => _medium(18.0);

  TextStyle? get medium20 => _medium(20.0);

  TextStyle? get medium22 => _medium(22.0);

  TextStyle? get medium24 => _medium(24.0);

  TextStyle? get medium28 => _medium(28.0);

  TextStyle? get medium32 => _medium(32.0);

  TextStyle? get medium36 => _medium(36.0);

  TextStyle? get medium42 => _medium(42.0);

  TextStyle? get medium48 => _medium(48.0);

  // Semi-Bold Styles
  TextStyle? get semibold8 => _semibold(8.0);

  TextStyle? get semibold10 => _semibold(10.0);

  TextStyle? get semibold12 => _semibold(12.0);

  TextStyle? get semibold14 => _semibold(14.0);

  TextStyle? get semibold16 => _semibold(16.0);

  TextStyle? get semibold18 => _semibold(18.0);

  TextStyle? get semibold20 => _semibold(20.0);

  TextStyle? get semibold22 => _semibold(22.0);

  TextStyle? get semibold24 => _semibold(24.0);

  TextStyle? get semibold28 => _semibold(28.0);

  TextStyle? get semibold32 => _semibold(32.0);

  TextStyle? get semibold36 => _semibold(36.0);

  TextStyle? get semibold42 => _semibold(42.0);

  TextStyle? get semibold48 => _semibold(48.0);

  // Bold Styles
  TextStyle? get bold8 => _bold(8.0);

  TextStyle? get bold10 => _bold(10.0);

  TextStyle? get bold12 => _bold(12.0);

  TextStyle? get bold14 => _bold(14.0);

  TextStyle? get bold16 => _bold(16.0);

  TextStyle? get bold18 => _bold(18.0);

  TextStyle? get bold20 => _bold(20.0);

  TextStyle? get bold22 => _bold(22.0);

  TextStyle? get bold24 => _bold(24.0);

  TextStyle? get bold28 => _bold(28.0);

  TextStyle? get bold32 => _bold(32.0);

  TextStyle? get bold36 => _bold(36.0);

  TextStyle? get bold42 => _bold(42.0);

  TextStyle? get bold48 => _bold(48.0);
}
