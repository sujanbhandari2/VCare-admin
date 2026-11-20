import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_detail_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_create_edit_sheet.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_notes_section.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_snooze_sheet.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_assignees_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_option_picker_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class MyTaskDetailSheet extends ConsumerStatefulWidget {
  const MyTaskDetailSheet({
    super.key,
    required this.taskId,
    this.startInEditMode = false,
    this.onChanged,
  });

  final String taskId;
  final bool startInEditMode;
  final VoidCallback? onChanged;

  static Future<bool?> show(
    BuildContext context, {
    required String taskId,
    bool startInEditMode = false,
    VoidCallback? onChanged,
  }) {
    final id = taskId.trim();
    if (id.isEmpty) return Future.value();

    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      maxHeightFactor: 0.92,
      builder: (_) => MyTaskDetailSheet(
        taskId: id,
        startInEditMode: startInEditMode,
        onChanged: onChanged,
      ),
    );
  }

  @override
  ConsumerState<MyTaskDetailSheet> createState() => _MyTaskDetailSheetState();
}

class _MyTaskDetailSheetState extends ConsumerState<MyTaskDetailSheet> {
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(myTaskDetailStateProvider(widget.taskId).notifier).fetchDetail();
      if (ref.read(taskDetailAssigneesStateProvider).assignees.isEmpty) {
        ref.read(taskDetailAssigneesStateProvider.notifier).fetchAssignees();
      }
      if (widget.startInEditMode) {
        _openEdit();
      }
    });
  }

  void _markChanged() {
    _didChange = true;
    widget.onChanged?.call();
  }

  void _close() => Navigator.of(context).pop(_didChange ? true : null);

  Future<void> _openEdit() async {
    final detail = ref.read(myTaskDetailStateProvider(widget.taskId)).data;
    if (detail == null || !detail.isEditable) return;

    final saved = await MyTaskCreateEditSheet.show(context, existing: detail);
    if (saved == true && mounted) {
      _markChanged();
      await ref
          .read(myTaskDetailStateProvider(widget.taskId).notifier)
          .fetchDetail();
    }
  }

  Future<void> _complete() async {
    final l10n = context.appLocalization;
    await ref
        .read(myTaskDetailStateProvider(widget.taskId).notifier)
        .updateTask(
          request: const MyTaskUpdateRequest(status: MyTaskStatus.done),
          onCompleted: (success, error) {
            if (!mounted) return;
            if (!success) {
              context.showVcareToast(
                title: l10n.my_tasks_failed_complete,
                description: error,
                variant: VcareToastVariant.destructive,
              );
              return;
            }
            _markChanged();
            context.showVcareToast(
              title: l10n.my_tasks_completed,
              description: l10n.my_tasks_completed_desc,
              variant: VcareToastVariant.success,
            );
            _close();
          },
        );
  }

  Future<void> _changeStatus() async {
    final current = ref.read(myTaskDetailStateProvider(widget.taskId)).data;
    if (current == null) return;
    final l10n = context.appLocalization;

    final selected = await VcareOptionPickerSheet.show<MyTaskStatus>(
      context,
      title: l10n.my_tasks_task_status,
      options: MyTaskStatus.editableValues,
      labelOf: (value) => value.label,
      selected: current.status,
    );
    if (selected == null || !mounted || selected == current.status) return;

    await ref
        .read(myTaskDetailStateProvider(widget.taskId).notifier)
        .updateTask(
          request: MyTaskUpdateRequest(status: selected),
          onCompleted: (success, error) {
            if (!mounted) return;
            if (!success) {
              context.showVcareToast(
                title: l10n.my_tasks_failed_update_status,
                description: error,
                variant: VcareToastVariant.destructive,
              );
              return;
            }
            _markChanged();
            context.showVcareToast(
              title: l10n.my_tasks_status_updated,
              variant: VcareToastVariant.success,
            );
          },
        );
  }

  Future<void> _snooze() async {
    final until = await MyTaskSnoozeSheet.show(context);
    if (until == null || !mounted) return;
    final l10n = context.appLocalization;

    final ok = await ref
        .read(myTaskDetailStateProvider(widget.taskId).notifier)
        .snooze(
          until: until,
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: l10n.my_tasks_failed_snooze,
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );
    if (!mounted || !ok) return;
    _markChanged();
    context.showVcareToast(
      title: l10n.my_tasks_task_snoozed,
      variant: VcareToastVariant.success,
    );
    _close();
  }

  Future<void> _resume() async {
    final l10n = context.appLocalization;
    final ok = await ref
        .read(myTaskDetailStateProvider(widget.taskId).notifier)
        .resume(
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: l10n.my_tasks_failed_resume,
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );
    if (!mounted || !ok) return;
    _markChanged();
    context.showVcareToast(
      title: l10n.my_tasks_task_resumed,
      variant: VcareToastVariant.success,
    );
  }

  Future<void> _delete() async {
    final l10n = context.appLocalization;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.my_tasks_delete_confirm_title),
        content: Text(l10n.my_tasks_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: TextStyle(color: context.vcare.destructive),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(myTaskDetailStateProvider(widget.taskId).notifier)
        .delete(
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: l10n.my_tasks_failed_delete,
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );
    if (!mounted || !ok) return;
    _markChanged();
    context.showVcareToast(
      title: l10n.my_tasks_task_deleted,
      variant: VcareToastVariant.success,
    );
    _close();
  }

  void _openLinkedRecord(MyTask task) {
    final clientId = task.clientId?.trim();
    if (clientId != null && clientId.isNotEmpty) {
      context.pushNamed(
        AppRouter.clientDetailName,
        pathParameters: {'id': clientId},
      );
      return;
    }

    final category = task.category;
    final refId = task.categoryReferenceId?.trim();
    if (category == MyTaskCategory.referralCase &&
        refId != null &&
        refId.isNotEmpty) {
      context.pushNamed(
        AppRouter.caseDetailName,
        pathParameters: {'id': refId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final state = ref.watch(myTaskDetailStateProvider(widget.taskId));
    final task = state.data;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget body;
    if (task == null && !state.hasError) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (task == null) {
      body = VcareErrorStatePanel(
        title: l10n.my_tasks_unable_to_load_task,
        message: state.error,
        actionLabel: l10n.retry,
        onAction: () => ref
            .read(myTaskDetailStateProvider(widget.taskId).notifier)
            .fetchDetail(),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaChipRow(task: task, onStatusTap: _changeStatus),
          const SizedBox(height: 16),
          Text(
            l10n.my_tasks_description,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (task.description?.trim().isNotEmpty ?? false)
                ? task.description!.trim()
                : l10n.my_tasks_no_description,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontStyle: (task.description?.trim().isNotEmpty ?? false)
                  ? FontStyle.italic
                  : FontStyle.normal,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: l10n.my_tasks_assignee,
            value: resolveMyTaskPersonLabel(
              task.assignee,
              fallback: l10n.my_tasks_unassigned,
            ),
          ),
          if (task.dueDate != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: l10n.my_tasks_due,
              value: formatMyTaskDateTime(task.dueDate!),
              valueColor: task.isOverdue ? vcare.dangerScale.s500 : null,
            ),
          ],
          if (task.isSnoozed && task.snoozedTill != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: l10n.my_tasks_snoozed_until,
              value: formatMyTaskDateTime(task.snoozedTill!),
            ),
          ],
          if (task.displayClientName != 'No client') ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: l10n.my_tasks_client,
              value: task.displayClientName,
              onTap: () => _openLinkedRecord(task),
            ),
          ],
          if (task.category != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: l10n.my_tasks_category,
              value: task.category!.label,
            ),
          ],
          const SizedBox(height: 20),
          MyTaskNotesSection(taskId: widget.taskId),
        ],
      );
    }

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task?.title ?? l10n.my_tasks_view_task,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.my_tasks_review_subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task != null && task.isEditable)
                  IconButton(
                    onPressed: state.updating ? null : _openEdit,
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    color: vcare.mutedForeground,
                    tooltip: l10n.my_tasks_edit,
                  ),
                if (task != null)
                  IconButton(
                    onPressed: state.updating ? null : _delete,
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    color: vcare.destructive,
                    tooltip: l10n.delete,
                  ),
                IconButton(
                  onPressed: _close,
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: vcare.mutedForeground,
                  tooltip: l10n.my_tasks_close,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: vcare.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: body,
            ),
          ),
          if (task != null) ...[
            Divider(height: 1, color: vcare.border),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 12),
              child: Row(
                children: [
                  if (task.isSnoozed)
                    Expanded(
                      child: AppButton.outlined(
                        text: l10n.my_tasks_resume,
                        loading: state.updating,
                        onPressed: state.updating ? null : _resume,
                      ),
                    )
                  else if (task.isEditable)
                    Expanded(
                      child: AppButton.outlined(
                        text: l10n.my_tasks_snooze,
                        onPressed: state.updating ? null : _snooze,
                      ),
                    ),
                  if (task.isEditable) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.elevated(
                        text: l10n.my_tasks_complete,
                        loading: state.updating,
                        onPressed: state.updating ? null : _complete,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: AppButton.outlined(
                        text: l10n.my_tasks_close,
                        onPressed: _close,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChipRow extends StatelessWidget {
  const _MetaChipRow({required this.task, required this.onStatusTap});

  final MyTask task;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: Text(task.status.label),
          onPressed: task.isEditable ? onStatusTap : null,
        ),
        Chip(
          label: Text(task.priority.label),
          backgroundColor: task.priority == MyTaskPriority.urgent
              ? vcare.dangerScale.s50
              : null,
        ),
        if (task.origin == MyTaskOrigin.system)
          Chip(label: Text(l10n.my_tasks_origin_system)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? (onTap != null ? vcare.primary : null),
            ),
          ),
        ),
        if (onTap != null)
          Icon(
            LucideIcons.chevronRight,
            size: 14,
            color: vcare.mutedForeground,
          ),
      ],
    );

    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}
