import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_field.dart';
import 'package:vcare_admin/features/task_detail/utils/task_detail_formatters.dart';

/// Editable task fields. The linked record stays read-only, matching the web
/// drawer where the membership/case link is locked once a task exists.
class TaskDetailEditBody extends StatelessWidget {
  const TaskDetailEditBody({
    super.key,
    required this.detail,
    required this.titleController,
    required this.descriptionController,
    required this.assigneeLabel,
    required this.hasAssignee,
    required this.onPickAssignee,
    required this.dueDate,
    required this.onPickDueDate,
    required this.onClearDueDate,
    required this.priority,
    required this.onPickPriority,
    required this.status,
    required this.onPickStatus,
    required this.enabled,
  });

  final TaskDetail detail;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String assigneeLabel;
  final bool hasAssignee;
  final VoidCallback onPickAssignee;
  final DateTime? dueDate;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;
  final TaskDetailPriority priority;
  final VoidCallback onPickPriority;
  final TaskDetailStatus status;
  final VoidCallback onPickStatus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _EditLabel(label: 'Title', isRequired: true),
        const SizedBox(height: 6),
        TextField(
          controller: titleController,
          enabled: enabled,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Follow up on intake form',
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        const _EditLabel(label: 'Description'),
        const SizedBox(height: 6),
        TextField(
          controller: descriptionController,
          enabled: enabled,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Add more context about this task…',
            isDense: true,
          ),
        ),
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
          onTap: enabled ? onPickAssignee : null,
        ),
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Due date & time',
          value: formatTaskDetailDueDate(dueDate),
          icon: LucideIcons.calendar,
          isPlaceholder: dueDate == null,
          onTap: enabled ? onPickDueDate : null,
          onClear: enabled && dueDate != null ? onClearDueDate : null,
        ),
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Priority',
          value: priority.label,
          icon: LucideIcons.flag,
          dotColor: taskDetailPriorityColor(vcare, priority),
          onTap: enabled ? onPickPriority : null,
        ),
        const SizedBox(height: 16),
        TaskDetailField(
          label: 'Status',
          value: status.label,
          icon: LucideIcons.barChart2,
          onTap: enabled ? onPickStatus : null,
        ),
      ],
    );
  }
}

class _EditLabel extends StatelessWidget {
  const _EditLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: vcare.mutedForeground,
          ),
        ),
        if (isRequired)
          Text(
            ' *',
            style: TextStyle(fontSize: 11, color: vcare.destructive),
          ),
      ],
    );
  }
}
