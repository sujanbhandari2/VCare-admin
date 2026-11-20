import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_section_card.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_preview_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_detail_sheet.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_row.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_tasks_empty_state.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

class MyTasksPreviewCard extends ConsumerStatefulWidget {
  const MyTasksPreviewCard({super.key});

  @override
  ConsumerState<MyTasksPreviewCard> createState() => _MyTasksPreviewCardState();
}

class _MyTasksPreviewCardState extends ConsumerState<MyTasksPreviewCard> {
  Future<void> _openTask(String taskId) {
    return MyTaskDetailSheet.show(
      context,
      taskId: taskId,
      onChanged: () => ref.read(myTasksPreviewStateProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final l10n = context.appLocalization;
    final state = ref.watch(myTasksPreviewStateProvider);
    final rows = state.items;
    final overdueCount = state.overdueCount;

    Widget body;
    if (state.loading) {
      body = AdminDashboardSectionMessage(message: l10n.my_tasks_loading);
    } else if (state.hasError) {
      body = VcareInlineErrorCard(
        title: l10n.my_tasks_unable_to_load,
        message: state.error,
        onRetry: () => ref.read(myTasksPreviewStateProvider.notifier).refresh(),
      );
    } else if (rows.isEmpty) {
      body = const MyTasksEmptyState();
    } else {
      body = Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            MyTaskRow(
              task: rows[i],
              compact: true,
              onTap: () => _openTask(rows[i].id),
            ),
            if (i < rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      );
    }

    return AdminDashboardSectionCard(
      title: l10n.my_tasks_title,
      badgeLabel: overdueCount > 0
          ? l10n.my_tasks_overdue_count(overdueCount)
          : null,
      badgeColor: vcare.destructive,
      showViewAll: !state.loading && !state.hasError && rows.isNotEmpty,
      onViewAll: () => context.pushNamed(AppRouter.myTasksName),
      child: body,
    );
  }
}
