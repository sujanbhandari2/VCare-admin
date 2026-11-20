import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_detail_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_assignees_state_provider.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_assignee_picker_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_option_picker_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class MyTaskCreateEditSheet extends ConsumerStatefulWidget {
  const MyTaskCreateEditSheet({super.key, this.existing});

  final MyTask? existing;

  static Future<bool?> show(BuildContext context, {MyTask? existing}) {
    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      maxHeightFactor: 0.92,
      builder: (_) => MyTaskCreateEditSheet(existing: existing),
    );
  }

  @override
  ConsumerState<MyTaskCreateEditSheet> createState() =>
      _MyTaskCreateEditSheetState();
}

class _MyTaskCreateEditSheetState extends ConsumerState<MyTaskCreateEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _titleFocusNode = FocusNode();

  String? _assigneeId;
  String _assigneeLabel = '';
  DateTime? _dueDate;
  DateTime? _originalDueDate;
  MyTaskPriority _priority = MyTaskPriority.medium;
  MyTaskStatus _status = MyTaskStatus.toDo;
  bool _saving = false;
  bool _autovalidate = false;
  String? _dueDateError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      _assigneeId = existing.assignee?.id;
      final name = existing.assignee?.displayName.trim() ?? '';
      _assigneeLabel = name;
      _dueDate = existing.dueDate;
      _originalDueDate = existing.dueDate;
      _priority = existing.priority;
      _status = existing.status;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(taskDetailAssigneesStateProvider).assignees.isEmpty) {
        ref.read(taskDetailAssigneesStateProvider.notifier).fetchAssignees();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
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
      _dueDateError = null;
    });
  }

  Future<void> _pickPriority() async {
    final l10n = context.appLocalization;
    final selected = await VcareOptionPickerSheet.show<MyTaskPriority>(
      context,
      title: l10n.my_tasks_task_priority,
      options: MyTaskPriority.values,
      labelOf: (value) => value.label,
      selected: _priority,
    );
    if (selected == null || !mounted) return;
    setState(() => _priority = selected);
  }

  Future<void> _pickStatus() async {
    final l10n = context.appLocalization;
    final selected = await VcareOptionPickerSheet.show<MyTaskStatus>(
      context,
      title: l10n.my_tasks_task_status,
      options: MyTaskStatus.editableValues,
      labelOf: (value) => value.label,
      selected: _status,
    );
    if (selected == null || !mounted) return;
    setState(() => _status = selected);
  }

  Future<void> _save() async {
    final l10n = context.appLocalization;
    final formValid = _formKey.currentState?.validate() ?? false;

    final dueValid = isMyTaskDueDateValid(
      dueDate: _dueDate,
      originalDueDate: _originalDueDate,
    );

    setState(() {
      _autovalidate = true;
      _dueDateError = dueValid ? null : l10n.my_tasks_due_date_future;
    });

    if (!formValid || !dueValid) {
      if (!formValid) {
        _titleFocusNode.requestFocus();
      }
      return;
    }

    final title = _titleController.text.trim();
    setState(() => _saving = true);

    if (_isEdit) {
      final existing = widget.existing!;
      await ref
          .read(myTaskDetailStateProvider(existing.id).notifier)
          .updateTask(
            request: MyTaskUpdateRequest(
              title: title,
              description: _descriptionController.text,
              status: _status,
              priority: _priority,
              assignedTo: _assigneeId,
              clearAssignedTo: _assigneeId == null || _assigneeId!.isEmpty,
              dueDateIso: _dueDate?.toUtc().toIso8601String(),
              clearDueDate: _dueDate == null,
              category: existing.apiCategory,
              categoryReferenceId: existing.categoryReferenceId,
              clientId: existing.clientId,
            ),
            onCompleted: (success, error) {
              if (!mounted) return;
              setState(() => _saving = false);
              if (!success) {
                context.showVcareToast(
                  title: l10n.my_tasks_failed_update,
                  description: error,
                  variant: VcareToastVariant.destructive,
                );
                return;
              }
              final note = _noteController.text.trim();
              if (note.isNotEmpty) {
                ref
                    .read(myTaskDetailStateProvider(existing.id).notifier)
                    .addNote(note);
              }
              context.showVcareToast(
                title: l10n.my_tasks_task_updated,
                variant: VcareToastVariant.success,
              );
              Navigator.of(context).pop(true);
            },
          );
      return;
    }

    final created = await ref
        .read(myTaskCreateStateProvider.notifier)
        .create(
          request: MyTaskCreateRequest(
            title: title,
            description: _descriptionController.text,
            status: _status,
            priority: _priority,
            assignedTo: _assigneeId,
            dueDateIso: _dueDate?.toUtc().toIso8601String(),
            initialNote: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: l10n.my_tasks_failed_create,
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );

    if (!mounted) return;
    setState(() => _saving = false);
    if (created == null) return;

    context.showVcareToast(
      title: l10n.my_tasks_task_created,
      variant: VcareToastVariant.success,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final assigneeDisplay = _assigneeId == null || _assigneeLabel.isEmpty
        ? l10n.my_tasks_select_team_member
        : _assigneeLabel;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? l10n.my_tasks_edit_task : l10n.my_tasks_new_task,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  color: vcare.mutedForeground,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Flexible(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidate
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                        labelText: l10n.my_tasks_field_title,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      enabled: !_saving,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.my_tasks_title_required;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.my_tasks_description,
                        border: const OutlineInputBorder(),
                      ),
                      minLines: 3,
                      maxLines: 5,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 12),
                    _PickerTile(
                      label: l10n.my_tasks_assignee,
                      value: assigneeDisplay,
                      onTap: _saving ? null : _pickAssignee,
                    ),
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: l10n.my_tasks_due_date,
                      value: _dueDate == null
                          ? l10n.my_tasks_none
                          : formatMyTaskDateTime(_dueDate!),
                      errorText: _dueDateError,
                      onTap: _saving ? null : _pickDueDate,
                      onClear: _dueDate == null || _saving
                          ? null
                          : () => setState(() {
                              _dueDate = null;
                              _dueDateError = null;
                            }),
                    ),
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: l10n.my_tasks_priority,
                      value: _priority.label,
                      onTap: _saving ? null : _pickPriority,
                    ),
                    const SizedBox(height: 8),
                    _PickerTile(
                      label: l10n.my_tasks_status,
                      value: _status.label,
                      onTap: _saving ? null : _pickStatus,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: _isEdit
                            ? l10n.my_tasks_add_note_optional
                            : l10n.my_tasks_initial_note_optional,
                        border: const OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      enabled: !_saving,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: l10n.cancel,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.elevated(
                    text: _isEdit
                        ? l10n.my_tasks_save_changes
                        : l10n.my_tasks_create_task,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    this.errorText,
    this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final String? errorText;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: vcare.muted.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: hasError
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasError
                                ? Theme.of(context).colorScheme.error
                                : vcare.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear, size: 18),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    Icon(Icons.chevron_right, color: vcare.mutedForeground),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
