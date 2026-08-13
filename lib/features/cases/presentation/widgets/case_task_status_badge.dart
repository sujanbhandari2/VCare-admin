import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';

/// Task status badge — colors mirror the web `TASK_STATUS_CONFIG`.
class CaseTaskStatusBadge extends StatelessWidget {
  const CaseTaskStatusBadge({super.key, required this.status});

  final CaseTaskStatus status;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    final (Color background, Color foreground) = switch (status) {
      CaseTaskStatus.submitted => (
        vcare.infoScale.s100,
        vcare.infoScale.s700,
      ),
      CaseTaskStatus.inProgress => (
        vcare.warningScale.s100,
        vcare.warningScale.s700,
      ),
      CaseTaskStatus.completed => (vcare.muted, vcare.foreground),
      CaseTaskStatus.cancelled => (
        vcare.dangerScale.s100,
        vcare.dangerScale.s700,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: VCareRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == CaseTaskStatus.completed) ...[
            Icon(LucideIcons.checkCircle, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
