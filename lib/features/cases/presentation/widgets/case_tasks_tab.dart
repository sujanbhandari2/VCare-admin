import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_tasks_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_task_form_sheet.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_task_status_badge.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_empty_state_card.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Tasks tab with progress bar and create/edit.
class CaseTasksTab extends ConsumerWidget {
  const CaseTasksTab({
    super.key,
    required this.caseId,
    required this.clientId,
  });

  final String caseId;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vcare = context.vcare;
    final state = ref.watch(caseTasksStateProvider(caseId));
    final total = state.tasks.length;
    final completed = state.completedCount;
    final progress = total == 0 ? 0.0 : completed / total;

    return ListView(
      physics: VcareRefreshScrollView.physics,
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        context.mobileShellBottomContentPadding,
      ),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: state.mutating
                ? null
                : () => CaseTaskFormSheet.show(
                    context,
                    caseId: caseId,
                    clientId: clientId,
                  ),
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Create Task'),
            style: OutlinedButton.styleFrom(
              foregroundColor: vcare.mutedForeground,
              side: BorderSide(color: vcare.border),
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: VCareRadius.mdAll),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (total > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vcare.muted,
              borderRadius: VCareRadius.lgAll,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$completed of $total ${total == 1 ? 'task' : 'tasks'}'
                        ' completed',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: vcare.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: VCareRadius.fullAll,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: vcare.border,
                    color: context.vcare.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (state.isInitialLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'Loading tasks...',
                style: TextStyle(
                  fontSize: 13,
                  color: vcare.mutedForeground,
                ),
              ),
            ),
          )
        else if (state.error != null && state.tasks.isEmpty)
          VcareInlineErrorCard(
            message: state.error ?? 'Unable to load tasks.',
            onRetry: () =>
                ref.read(caseTasksStateProvider(caseId).notifier).fetchTasks(),
          )
        else if (state.tasks.isEmpty)
          const VcareEmptyStateCard(
            icon: LucideIcons.checkSquare,
            title: 'No tasks yet',
            description: 'Create a task to track work on this case.',
          )
        else
          for (var i = 0; i < state.tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _CaseTaskRow(
              task: state.tasks[i],
              onTap: () => CaseTaskFormSheet.show(
                context,
                caseId: caseId,
                clientId: clientId,
                task: state.tasks[i],
              ),
            ),
          ],
      ],
    );
  }
}

class _CaseTaskRow extends StatelessWidget {
  const _CaseTaskRow({required this.task, required this.onTap});

  final CaseTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final done = task.status == CaseTaskStatus.completed || task.completed;
    final dueDate = task.dueDate?.trim() ?? '';

    return Material(
      color: done ? vcare.successScale.s50 : vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.lgAll,
        side: BorderSide(
          color: done ? vcare.successScale.s200 : vcare.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? LucideIcons.checkSquare : LucideIcons.square,
                size: 16,
                color: done ? context.vcare.success : vcare.mutedForeground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? vcare.mutedForeground : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TaskMeta(
                          icon: LucideIcons.user,
                          label: task.assignee.trim().isEmpty
                              ? 'Unassigned'
                              : task.assignee,
                        ),
                        if (dueDate.isNotEmpty)
                          _TaskMeta(
                            icon: LucideIcons.clock,
                            label: formatTaskDueDate(dueDate),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CaseTaskStatusBadge(status: task.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: vcare.mutedForeground),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
        ),
      ],
    );
  }
}
