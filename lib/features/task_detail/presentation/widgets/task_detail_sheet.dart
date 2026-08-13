import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_assignees_state_provider.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_state_provider.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_assignee_picker_sheet.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_edit_body.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_skeleton.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_view_body.dart';
import 'package:vcare_admin/features/task_detail/utils/task_detail_person_label.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_option_picker_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Task detail — parity with the web "View Task" / "Edit Task" drawer, which
/// swaps modes in place instead of opening a second sheet.
class TaskDetailSheet extends ConsumerStatefulWidget {
  const TaskDetailSheet({
    super.key,
    required this.taskId,
    this.startInEditMode = false,
    this.onSaved,
  });

  final String taskId;

  /// Opens straight into edit mode, for the row-level edit action.
  final bool startInEditMode;

  /// Called after each successful save so lists can refresh.
  final VoidCallback? onSaved;

  /// Resolves to `true` when the task was saved at least once.
  static Future<bool?> show(
    BuildContext context, {
    required String taskId,
    bool startInEditMode = false,
    VoidCallback? onSaved,
  }) {
    final id = taskId.trim();
    if (id.isEmpty) return Future.value();

    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      maxHeightFactor: 0.92,
      builder: (_) => TaskDetailSheet(
        taskId: id,
        startInEditMode: startInEditMode,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _editing = false;
  bool _formSeeded = false;
  bool _didSave = false;

  String? _assigneeId;
  String _assigneeLabel = 'Select team member';
  DateTime? _dueDate;
  DateTime? _originalDueDate;
  TaskDetailPriority _priority = TaskDetailPriority.medium;
  TaskDetailStatus _status = TaskDetailStatus.toDo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The notifier is kept alive per task id, so reopening revalidates while
      // the cached task stays on screen.
      ref.read(taskDetailStateProvider(widget.taskId).notifier).fetchDetail();
      // Team members resolve the assignee/creator ids the task carries, so they
      // are needed in view mode too.
      if (ref.read(taskDetailAssigneesStateProvider).assignees.isEmpty) {
        ref.read(taskDetailAssigneesStateProvider.notifier).fetchAssignees();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _seedForm(TaskDetail detail) {
    _titleController.text = detail.title;
    _descriptionController.text = detail.description ?? '';
    _assigneeId = detail.assignee?.id;
    _assigneeLabel = resolveTaskDetailPersonLabel(
      detail.assignee,
      ref.read(taskDetailAssigneesStateProvider).assignees,
      fallback: 'Select team member',
    );
    _dueDate = detail.dueDate;
    _originalDueDate = detail.dueDate;
    _priority = detail.priority;
    _status = detail.status;
    _formSeeded = true;
  }

  void _startEditing(TaskDetail detail) {
    setState(() {
      _seedForm(detail);
      _editing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _formSeeded = false;
    });
  }

  void _close() => Navigator.of(context).pop(_didSave ? true : null);

  /// Web `isAllowedTaskDueDateIso`: due dates must be in the future unless the
  /// task already carried that value.
  bool get _dueDateIsValid {
    final dueDate = _dueDate;
    if (dueDate == null) return true;
    if (dueDate.isAfter(DateTime.now())) return true;
    final original = _originalDueDate;
    return original != null && original.isAtSameMomentAs(dueDate);
  }

  Future<void> _pickAssignee() async {
    final selected = await TaskDetailAssigneePickerSheet.show(
      context,
      selectedId: _assigneeId,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _assigneeId = selected.id;
      _assigneeLabel = selected.displayName;
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final current = _dueDate;
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate = current != null && current.isAfter(firstDate)
        ? current
        : now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? initialDate),
    );
    if (!mounted) return;

    setState(() {
      _dueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 9,
        pickedTime?.minute ?? 0,
      );
    });
  }

  Future<void> _pickPriority() async {
    final selected = await VcareOptionPickerSheet.show<TaskDetailPriority>(
      context,
      title: 'Task priority',
      options: TaskDetailPriority.values,
      labelOf: (value) => value.label,
      selected: _priority,
    );
    if (selected == null || !mounted) return;
    setState(() => _priority = selected);
  }

  Future<void> _pickStatus() async {
    final options = [
      ...TaskDetailStatus.editableValues,
      if (!TaskDetailStatus.editableValues.contains(_status)) _status,
    ];

    final selected = await VcareOptionPickerSheet.show<TaskDetailStatus>(
      context,
      title: 'Task status',
      options: options,
      labelOf: (value) => value.label,
      selected: _status,
    );
    if (selected == null || !mounted) return;
    setState(() => _status = selected);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      context.showVcareToast(
        title: 'Title is required',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final assigneeId = _assigneeId?.trim();
    if (assigneeId == null || assigneeId.isEmpty) {
      context.showVcareToast(
        title: 'Assignee required',
        description: 'Please select a team member to assign this task to.',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    if (!_dueDateIsValid) {
      context.showVcareToast(
        title: 'Due date must be in the future',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    await ref
        .read(taskDetailStateProvider(widget.taskId).notifier)
        .updateTask(
          title: title,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          assignedTo: assigneeId,
          dueDateIso: _dueDate?.toUtc().toIso8601String(),
          onCompleted: (success, error) {
            if (!mounted) return;
            if (!success) {
              context.showVcareToast(
                title: 'Failed to update task',
                description: error,
                variant: VcareToastVariant.destructive,
              );
              return;
            }

            setState(() {
              _didSave = true;
              _editing = false;
              _formSeeded = false;
            });
            widget.onSaved?.call();
            context.showVcareToast(
              title: 'Task updated',
              description: 'Your changes were saved.',
              variant: VcareToastVariant.success,
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final state = ref.watch(taskDetailStateProvider(widget.taskId));
    final detail = state.data;
    final teamMembers = ref.watch(taskDetailAssigneesStateProvider).assignees;

    if (detail != null && widget.startInEditMode && !_editing && !_formSeeded) {
      // Deferred until the task loads, since edit mode needs its values.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && detail.isEditable) _startEditing(detail);
      });
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget body;
    if (detail == null && !state.hasError) {
      // Also covers the frame before the first fetch starts.
      body = const TaskDetailSkeleton();
    } else if (detail == null) {
      body = VcareErrorStatePanel(
        title: 'Unable to load task',
        message: state.error,
        actionLabel: 'Try again',
        onAction: () => ref
            .read(taskDetailStateProvider(widget.taskId).notifier)
            .fetchDetail(),
      );
    } else if (_editing) {
      body = TaskDetailEditBody(
        detail: detail,
        titleController: _titleController,
        descriptionController: _descriptionController,
        assigneeLabel: _assigneeLabel,
        hasAssignee: _assigneeId?.trim().isNotEmpty ?? false,
        onPickAssignee: _pickAssignee,
        dueDate: _dueDate,
        onPickDueDate: _pickDueDate,
        onClearDueDate: () => setState(() => _dueDate = null),
        priority: _priority,
        onPickPriority: _pickPriority,
        status: _status,
        onPickStatus: _pickStatus,
        enabled: !state.updating,
      );
    } else {
      body = TaskDetailViewBody(
        detail: detail,
        assigneeLabel: resolveTaskDetailPersonLabel(
          detail.assignee,
          teamMembers,
          fallback: 'Unassigned',
        ),
        hasAssignee: detail.assignee != null,
      );
    }

    final createdByLabel = detail?.createdBy == null
        ? ''
        : resolveTaskDetailPersonLabel(
            detail!.createdBy,
            teamMembers,
            fallback: '',
          );

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editing ? 'Edit Task' : 'View Task',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _editing
                            ? 'Update task details and assignment.'
                            : 'Review task details and progress.',
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _close,
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: vcare.mutedForeground,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: vcare.border),
          // Loose fit so short tasks keep the sheet compact while long ones
          // scroll up to the sheet's max height.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: body,
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            child: _editing
                ? Row(
                    children: [
                      Expanded(
                        child: AppButton.outlined(
                          text: 'Cancel',
                          onPressed: state.updating ? null : _cancelEditing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.elevated(
                          text: 'Save changes',
                          loading: state.updating,
                          onPressed: state.updating ? null : _save,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          createdByLabel.isEmpty
                              ? ''
                              : 'Created by $createdByLabel',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Completed tasks can't be edited, matching the web
                      // drawer which hides Edit for done tasks.
                      if (detail != null && detail.isEditable)
                        SizedBox(
                          width: 96,
                          child: AppButton.outlined(
                            text: 'Edit',
                            onPressed: () => _startEditing(detail),
                          ),
                        ),
                      if (detail != null && detail.isEditable)
                        const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        child: AppButton.outlined(
                          text: 'Close',
                          onPressed: _close,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
