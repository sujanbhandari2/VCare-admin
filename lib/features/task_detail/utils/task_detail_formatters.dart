import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';

/// Due date format used by the web task drawer (`MM/dd/yyyy hh:mm a`).
String formatTaskDetailDueDate(DateTime? dueDate) {
  if (dueDate == null) return 'Not set';
  return DateFormat('MM/dd/yyyy hh:mm a').format(dueDate);
}

/// Priority dot colors — parity with the web `PRIORITY_OPTIONS` swatches.
Color taskDetailPriorityColor(
  VCareThemeExtension vcare,
  TaskDetailPriority priority,
) {
  return switch (priority) {
    TaskDetailPriority.low => vcare.mutedForeground,
    TaskDetailPriority.medium => vcare.infoScale.s500,
    TaskDetailPriority.high => vcare.warningScale.s500,
    TaskDetailPriority.urgent => vcare.dangerScale.s500,
  };
}
