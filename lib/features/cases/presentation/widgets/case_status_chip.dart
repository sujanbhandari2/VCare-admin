import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';

/// Status chip for [CaseStatus] — tones mirror the web console `statusConfig`.
///
/// Also used for note status badges, matching the web `NoteStatusBadge`, which
/// delegates to the same case status badge.
class CaseStatusChip extends StatelessWidget {
  const CaseStatusChip({super.key, required this.status});

  final CaseStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = resolveCaseStatusChipColors(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VCareSpacing.s2,
        vertical: VCareSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: VCareRadius.fullAll,
        border: Border.all(color: colors.border),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.foreground,
        ),
      ),
    );
  }
}

/// Web parity map (`CaseStatusBadge.statusConfig`):
/// new → secondary, requested → info-100/700, in_progress → warning-100/700,
/// closed → body-100/700, deleted → danger-100/700, all with transparent border.
CaseChipColors resolveCaseStatusChipColors(
  BuildContext context,
  CaseStatus status,
) {
  final vcare = context.vcare;

  return switch (status) {
    CaseStatus.newCase => CaseChipColors(
      background: vcare.secondary,
      foreground: VCareColors.secondaryForeground,
      border: Colors.transparent,
    ),
    CaseStatus.requested => CaseChipColors(
      background: vcare.infoScale.s100,
      foreground: vcare.infoScale.s700,
      border: Colors.transparent,
    ),
    CaseStatus.inProgress => CaseChipColors(
      background: vcare.warningScale.s100,
      foreground: vcare.warningScale.s700,
      border: Colors.transparent,
    ),
    CaseStatus.closed => CaseChipColors(
      background: vcare.muted,
      foreground: vcare.foreground,
      border: Colors.transparent,
    ),
    CaseStatus.deleted => CaseChipColors(
      background: vcare.dangerScale.s100,
      foreground: vcare.dangerScale.s700,
      border: Colors.transparent,
    ),
  };
}

enum CaseChipTone { success, warning, destructive, info, muted }

class CaseChipColors {
  const CaseChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

CaseChipColors resolveCaseChipColors(BuildContext context, CaseChipTone tone) {
  final status = VCareStatusColors.of(context, _toStatusTone(tone));
  return CaseChipColors(
    background: status.background,
    foreground: status.foreground,
    border: status.border,
  );
}

VCareStatusTone _toStatusTone(CaseChipTone tone) {
  return switch (tone) {
    CaseChipTone.success => VCareStatusTone.success,
    CaseChipTone.warning => VCareStatusTone.warning,
    CaseChipTone.destructive => VCareStatusTone.danger,
    CaseChipTone.info => VCareStatusTone.info,
    CaseChipTone.muted => VCareStatusTone.neutral,
  };
}
