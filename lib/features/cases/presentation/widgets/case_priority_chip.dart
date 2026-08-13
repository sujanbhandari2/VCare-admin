import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_status_chip.dart';

/// Priority chip for [CasePriority] — tone colors match [ClientStatusChip].
class CasePriorityChip extends StatelessWidget {
  const CasePriorityChip({super.key, required this.priority});

  final CasePriority priority;

  @override
  Widget build(BuildContext context) {
    final colors = resolveCaseChipColors(context, _toneFor(priority));

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
        priority.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }

  static CaseChipTone _toneFor(CasePriority priority) {
    switch (priority) {
      case CasePriority.urgent:
        return CaseChipTone.destructive;
      case CasePriority.high:
        return CaseChipTone.warning;
      case CasePriority.medium:
        return CaseChipTone.info;
      case CasePriority.low:
        return CaseChipTone.muted;
    }
  }
}
