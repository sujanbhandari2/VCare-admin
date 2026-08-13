import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_detail_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_tasks_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_assignee_picker_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_option_picker_sheet.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Create / edit task bottom sheet.
class CaseTaskFormSheet extends ConsumerStatefulWidget {
  const CaseTaskFormSheet({
    super.key,
    required this.caseId,
    required this.clientId,
    this.task,
  });

  final String caseId;
  final String clientId;
  final CaseTask? task;

  static Future<void> show(
    BuildContext context, {
    required String caseId,
    required String clientId,
    CaseTask? task,
  }) {
    return context.showBottomSheet<void>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CaseTaskFormSheet(
        caseId: caseId,
        clientId: clientId,
        task: task,
      ),
    );
  }

  @override
  ConsumerState<CaseTaskFormSheet> createState() => _CaseTaskFormSheetState();
}

class _CaseTaskFormSheetState extends ConsumerState<CaseTaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late CaseTaskStatus _status;
  late CasePriority _priority;
  String? _assigneeId;
  String _assigneeLabel = 'Unassigned';
  DateTime? _dueDate;
  String? _originalDueDate;
  bool _submitting = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final detail = ref
        .read(caseDetailStateProvider(widget.caseId))
        .data;

    _titleController = TextEditingController(
      text:
          task?.title ??
          (detail == null || detail.title.trim().isEmpty
              ? ''
              : 'Case follow-up: ${detail.title.trim()}'),
    );
    _descriptionController = TextEditingController(
      text: task?.description ?? detail?.description ?? '',
    );
    _status = task?.status ?? CaseTaskStatus.submitted;
    _priority = CasePriority.fromApi(task?.priority);
    _assigneeId = task?.assigneeId;
    _assigneeLabel = (task?.assignee.trim().isNotEmpty ?? false)
        ? task!.assignee
        : 'Unassigned';
    _originalDueDate = task?.dueDate?.trim();
    _dueDate = _parseDueDate(task?.dueDate);
  }

  static DateTime? _parseDueDate(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed.toLocal();
    return parseDisplayDate(trimmed);
  }

  /// Web `isAllowedTaskDueDateIso`: due dates must be in the future unless the
  /// task already carried that value.
  bool get _dueDateIsValid {
    final dueDate = _dueDate;
    if (dueDate == null) return true;
    if (dueDate.isAfter(DateTime.now())) return true;
    final original = _parseDueDate(_originalDueDate);
    return original != null && original.isAtSameMomentAs(dueDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  void _clearDueDate() => setState(() => _dueDate = null);

  Future<void> _pickAssignee() async {
    final result = await CaseAssigneePickerSheet.show(
      context,
      selectedId: _assigneeId,
    );
    if (result == null || !mounted) return;
    setState(() {
      if (result.cleared) {
        _assigneeId = null;
        _assigneeLabel = 'Unassigned';
      } else if (result.assignee != null) {
        _assigneeId = result.assignee!.id;
        _assigneeLabel = result.assignee!.fullName;
      }
    });
  }

  Future<void> _pickStatus() async {
    final selected = await VcareOptionPickerSheet.show<CaseTaskStatus>(
      context,
      title: 'Task status',
      options: CaseTaskStatus.values,
      labelOf: (value) => value.label,
      selected: _status,
    );
    if (selected == null || !mounted) return;
    setState(() => _status = selected);
  }

  Future<void> _pickPriority() async {
    final selected = await VcareOptionPickerSheet.show<CasePriority>(
      context,
      title: 'Task priority',
      options: CasePriority.values,
      labelOf: (value) => value.label,
      selected: _priority,
    );
    if (selected == null || !mounted) return;
    setState(() => _priority = selected);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _submitting) return;

    if (!_dueDateIsValid) {
      context.showVcareToast(
        title: 'Due date and time must be in the future',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    setState(() => _submitting = true);
    final notifier = ref.read(caseTasksStateProvider(widget.caseId).notifier);
    final dueDateIso = _dueDate?.toUtc().toIso8601String();

    if (_isEditing) {
      await notifier.updateTask(
        taskId: widget.task!.id,
        title: title,
        description: _descriptionController.text.trim(),
        status: _status,
        priority: _priority.apiValue,
        assignedTo: _assigneeId,
        clearAssignedTo: _assigneeId == null,
        dueDate: dueDateIso,
        clientId: widget.clientId,
        onCompleted: (updated, error) {
          if (!mounted) return;
          if (updated != null) {
            context.showVcareToast(
              title: 'Task updated',
              description: 'Your changes were saved.',
              variant: VcareToastVariant.success,
            );
            context.pop();
            return;
          }
          setState(() => _submitting = false);
          context.showVcareToast(
            title: error ?? 'Unable to update task',
            variant: VcareToastVariant.destructive,
          );
        },
      );
    } else {
      await notifier.createTask(
        clientId: widget.clientId,
        title: title,
        description: _descriptionController.text.trim(),
        status: _status,
        priority: _priority.apiValue,
        assignedTo: _assigneeId,
        dueDate: dueDateIso,
        onCompleted: (created, error) {
          if (!mounted) return;
          if (created != null) {
            context.showVcareToast(
              title: 'Task created',
              description: 'Task created successfully.',
              variant: VcareToastVariant.success,
            );
            context.pop();
            return;
          }
          setState(() => _submitting = false);
          context.showVcareToast(
            title: error ?? 'Unable to create task',
            variant: VcareToastVariant.destructive,
          );
        },
      );
    }

    if (mounted && _submitting) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Task' : 'Create Task',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _isEditing
                  ? 'Update task details and assignment.'
                  : 'Add a new task and assign it to a team member.',
              style: TextStyle(
                fontSize: 12,
                color: context.vcare.mutedForeground,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What needs to be done?',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional details',
              ),
            ),
            const SizedBox(height: 12),
            _FormTile(
              icon: LucideIcons.user,
              label: 'Assignee',
              value: _assigneeLabel,
              onTap: _pickAssignee,
            ),
            _FormTile(
              icon: LucideIcons.calendar,
              label: 'Due date & time',
              value: _dueDate == null
                  ? 'Not set'
                  : DateFormat('MM/dd/yyyy hh:mm a').format(_dueDate!),
              onTap: _pickDueDate,
              onClear: _dueDate == null ? null : _clearDueDate,
            ),
            _FormTile(
              icon: LucideIcons.flag,
              label: 'Priority',
              value: _priority.label,
              onTap: _pickPriority,
            ),
            _FormTile(
              icon: LucideIcons.circleDot,
              label: 'Status',
              value: _status.label,
              onTap: _pickStatus,
            ),
            const SizedBox(height: 16),
            AppButton.elevated(
              text: _isEditing ? 'Save changes' : 'Create Task',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormTile extends StatelessWidget {
  const _FormTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 18, color: vcare.mutedForeground),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(LucideIcons.x, size: 16),
              color: vcare.mutedForeground,
              visualDensity: VisualDensity.compact,
              tooltip: 'Clear',
            ),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: vcare.mutedForeground,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
