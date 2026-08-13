import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Semantic status tones for chips/badges — uses branded theme scales.
enum VCareStatusTone { success, warning, danger, info, neutral, primary }

class VCareStatusColors {
  const VCareStatusColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;

  static VCareStatusColors of(BuildContext context, VCareStatusTone tone) {
    final vcare = context.vcare;
    return switch (tone) {
      VCareStatusTone.success => VCareStatusColors(
        foreground: vcare.successScale.s700,
        background: vcare.successScale.s50,
        border: vcare.successScale.s200,
      ),
      VCareStatusTone.warning => VCareStatusColors(
        foreground: vcare.warningScale.s700,
        background: vcare.warningScale.s50,
        border: vcare.warningScale.s200,
      ),
      VCareStatusTone.danger => VCareStatusColors(
        foreground: vcare.dangerScale.s700,
        background: vcare.dangerScale.s50,
        border: vcare.dangerScale.s200,
      ),
      VCareStatusTone.info => VCareStatusColors(
        foreground: vcare.infoScale.s700,
        background: vcare.infoScale.s50,
        border: vcare.infoScale.s200,
      ),
      VCareStatusTone.primary => VCareStatusColors(
        foreground: vcare.primaryScale.s700,
        background: vcare.primaryScale.s50,
        border: vcare.primaryScale.s200,
      ),
      VCareStatusTone.neutral => VCareStatusColors(
        foreground: vcare.mutedForeground,
        background: vcare.muted,
        border: vcare.border,
      ),
    };
  }
}
