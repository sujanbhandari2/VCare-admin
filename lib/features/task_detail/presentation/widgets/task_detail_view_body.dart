import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_field.dart';
import 'package:vcare_admin/features/task_detail/utils/task_detail_formatters.dart';

/// Read-only task fields, mirroring the web drawer's view mode.
class TaskDetailViewBody extends StatelessWidget {
  const TaskDetailViewBody({
    super.key,
    required this.detail,
    required this.assigneeLabel,
    required this.hasAssignee,
  });

  final TaskDetail detail;

  /// Resolved team-member name, since the task itself only carries a user id.
  final String assigneeLabel;
  final bool hasAssignee;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final title = detail.title.trim();
    final description = detail.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TaskDetailField(
          label: 'Title',
          value: title.isEmpty ? 'Untitled task' : title,
          isPlaceholder: title.isEmpty,
          maxLines: 3,
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 16),
          TaskDetailField(
            label: 'Description',
            value: description,
            maxLines: 8,
          ),
        ],
        if (detail.hasLinkedRecord) ...[
          const SizedBox(height: 16),
          TaskDetailField(
            label: detail.linkKind.label,
            value: detail.linkedRecordLabel,
            icon: LucideIcons.link2,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Assigned to',
          value: assigneeLabel,
          icon: LucideIcons.user,
          isPlaceholder: !hasAssignee,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Due date & time',
          value: formatTaskDetailDueDate(detail.dueDate),
          icon: LucideIcons.calendar,
          isPlaceholder: detail.dueDate == null,
        ),
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Priority',
          value: detail.priority.label,
          icon: LucideIcons.flag,
          dotColor: taskDetailPriorityColor(vcare, detail.priority),
        ),
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Status',
          value: detail.status.label,
          icon: LucideIcons.barChart2,
        ),
      ],
    );
  }
}
