import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';

/// Legacy palette — aliases to web-aligned [VCareColors].
/// Prefer `context.vcare` / `Theme.of(context).colorScheme` in new code.
class AppColors {
  AppColors._();

  static Color get primaryColor => VCareColors.primary;
  static Color get secondary => VCareColors.secondary;
  static const transparent = Colors.transparent;
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF212121);
  static Color get grey => VCareColors.mutedForeground;
  static Color get greyLight => VCareColors.border;
  static Color get red => VCareColors.destructive;
  static Color get lightRed => VCareColors.destructive.withValues(alpha: 0.12);
  static Color get green => VCareColors.success;
  static Color get lightGreen => VCareColors.success.withValues(alpha: 0.12);
}
