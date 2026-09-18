import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_todo_list_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/state/admin_dashboard_state.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_empty_states.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_section_card.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_todo_row.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class AdminDashboardTodoCard extends ConsumerStatefulWidget {
  const AdminDashboardTodoCard({super.key, required this.state});

  final AdminDashboardState state;

  @override
  ConsumerState<AdminDashboardTodoCard> createState() =>
      _AdminDashboardTodoCardState();
}

class _AdminDashboardTodoCardState
    extends ConsumerState<AdminDashboardTodoCard> {
  String? _completingTaskId;

  Future<void> _openTask(String taskId) {
    return TaskDetailSheet.show(
      context,
      taskId: taskId,
      onSaved: () => ref
          .read(adminTodoListStateProvider.notifier)
          .sync(onlyIfLoaded: true),
    );
  }

  Future<void> _completeTask(String taskId) async {
    if (_completingTaskId != null) return;
    setState(() => _completingTaskId = taskId);

    final ok = await ref
        .read(adminTodoListStateProvider.notifier)
        .completeTask(
          taskId: taskId,
          onError: (message) {
            if (!mounted) return;
            context.showVcareToast(
              title: 'Failed to complete task',
              description: message,
              variant: VcareToastVariant.destructive,
            );
          },
        );

    if (!mounted) return;
    setState(() => _completingTaskId = null);

    if (ok) {
      context.showVcareToast(
        title: 'Task completed',
        description: 'The task was marked as complete.',
        variant: VcareToastVariant.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final state = widget.state;
    final operation = state.todoTasksOperation;
    final rows = state.todoRows;
    final overdueCount = state.overdueCount;

    Widget body;
    if (operation.isLoading && rows.isEmpty) {
      body = const AdminDashboardSectionMessage(message: 'Loading todos…');
    } else if (operation.hasError && rows.isEmpty) {
      body = VcareInlineErrorCard(
        title: 'Unable to load todos',
        message: operation.errorMessage,
        onRetry: () =>
            ref.read(adminDashboardStateProvider.notifier).refreshTodoTasks(),
      );
    } else if (rows.isEmpty) {
      body = const AdminDashboardTodoEmptyState();
    } else {
      body = Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            AdminDashboardTodoRow(
              item: rows[i],
              isCompleting: _completingTaskId == rows[i].resource.id,
              onComplete: _completeTask,
              onTap: () => _openTask(rows[i].resource.id),
            ),
            if (i < rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      );
    }

    return AdminDashboardSectionCard(
      title: 'My Todo List',
      badgeLabel: overdueCount > 0 ? '$overdueCount overdue' : null,
      badgeColor: vcare.destructive,
      showViewAll:
          !operation.isLoading && !operation.hasError && rows.isNotEmpty,
      onViewAll: () => context.pushNamed(AppRouter.adminTodoListName),
      child: body,
    );
  }
}
