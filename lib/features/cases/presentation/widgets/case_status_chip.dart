import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';

/// Status chip for [CaseStatus] — tones mirror the web console `statusConfig`.
///
/// Also used for note status badges, matching the web `NoteStatusBadge`, which
/// delegates to the same case status badge.
class CaseStatusChip extends StatelessWidget {
  const CaseStatusChip({
    super.key,
    required this.status,
    this.useNotePalette = false,
  });

  final CaseStatus status;

  /// Web `NoteStatusBadge` tints when true; `CaseStatusBadge` when false.
  final bool useNotePalette;

  @override
  Widget build(BuildContext context) {
    final colors = useNotePalette
        ? resolveNoteStatusChipColors(context, status)
        : resolveCaseStatusChipColors(context, status);

    // Note meta: web `NoteStatusBadge` — h-4, px-1.5, text-[10px].
    // Case list: web `Badge size="chip"` — intrinsic width/height, text-xs, px-2.5.
    final padding = useNotePalette
        ? const EdgeInsets.symmetric(horizontal: 6)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    final fontSize = useNotePalette ? 10.0 : 12.0;

    final label = Text(
      status.label,
      style: TextStyle(
        fontSize: fontSize,
        height: 1,
        fontWeight: FontWeight.w500,
        color: colors.foreground,
      ),
    );

    final child = useNotePalette
        ? SizedBox(height: 16, child: Center(child: label))
        : label;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: VCareRadius.fullAll,
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

/// Web parity map (`CaseStatusBadge.statusConfig`):
/// new → secondary, requested → info-100/700, in_progress → warning-100/700,
/// closed → body-100/700, deleted → danger-100/700, all with transparent border.
/// Web `NoteStatusBadge` color map.
CaseChipColors resolveNoteStatusChipColors(
  BuildContext context,
  CaseStatus status,
) {
  final vcare = context.vcare;

  return switch (status) {
    CaseStatus.newCase => CaseChipColors(
      background: vcare.secondaryScale.s100,
      foreground: vcare.secondaryScale.s700,
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
      foreground: vcare.mutedForeground,
      border: Colors.transparent,
    ),
    CaseStatus.deleted => CaseChipColors(
      background: vcare.dangerScale.s100,
      foreground: vcare.dangerScale.s700,
      border: Colors.transparent,
    ),
  };
}

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
