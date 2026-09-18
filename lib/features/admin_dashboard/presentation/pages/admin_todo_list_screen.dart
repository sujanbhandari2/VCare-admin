import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_todo_list_state_provider.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_empty_states.dart';
import 'package:vcare_admin/features/admin_dashboard/presentation/widgets/admin_dashboard_todo_row.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_sheet.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class AdminTodoListScreen extends ConsumerStatefulWidget {
  const AdminTodoListScreen({super.key});

  @override
  ConsumerState<AdminTodoListScreen> createState() =>
      _AdminTodoListScreenState();
}

class _AdminTodoListScreenState extends ConsumerState<AdminTodoListScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  bool _isLoadMoreRequested = false;
  String? _completingTaskId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(adminTodoListStateProvider);
      if (state.isInitialLoading || state.isRefreshing) return;

      final notifier = ref.read(adminTodoListStateProvider.notifier);
      if (state.items.isEmpty) {
        if (!state.isInitialError) notifier.loadInitial();
        return;
      }

      // The list is kept alive, so re-entering the screen revalidates the
      // cached page instead of showing whatever was loaded last time.
      notifier.refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final listState = ref.read(adminTodoListStateProvider);
    final shouldLoadMore =
        listState.hasMore &&
        listState.items.isNotEmpty &&
        !listState.isLoadingMore &&
        listState.loadMoreErrorMessage == null &&
        !listState.isInitialLoading &&
        !listState.isInitialError &&
        !_isLoadMoreRequested &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreTriggerThreshold;

    if (shouldLoadMore) {
      _isLoadMoreRequested = true;
      ref.read(adminTodoListStateProvider.notifier).loadMore().whenComplete(() {
        if (mounted) {
          _isLoadMoreRequested = false;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(adminTodoListStateProvider.notifier).sync();
  }

  Future<void> _openTask(String taskId, {bool editing = false}) {
    return TaskDetailSheet.show(
      context,
      taskId: taskId,
      startInEditMode: editing,
      onSaved: () => ref.read(adminTodoListStateProvider.notifier).sync(),
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
    if (!ok) return;

    context.showVcareToast(
      title: 'Task completed',
      description: 'The task was marked as complete.',
      variant: VcareToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(adminTodoListStateProvider);
    final items = listState.items;

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        controller: _scrollController,
        slivers: [
          const SliverVcarePageHeader(title: 'My Todo List', showBack: true),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: listState.isInitialLoading && items.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : listState.isInitialError && items.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: VcareErrorStatePanel(
                      title: 'Unable to load todos',
                      message: listState.operation.errorMessage,
                      actionLabel: 'Try again',
                      onAction: () => ref
                          .read(adminTodoListStateProvider.notifier)
                          .loadInitial(),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate([
                      if (items.isEmpty)
                        const AdminDashboardTodoEmptyState()
                      else ...[
                        for (var i = 0; i < items.length; i++) ...[
                          AdminDashboardTodoRow(
                            item: items[i],
                            isCompleting:
                                _completingTaskId == items[i].resource.id,
                            onComplete: _completeTask,
                            onTap: () => _openTask(items[i].resource.id),
                            onEdit: () =>
                                _openTask(items[i].resource.id, editing: true),
                          ),
                          if (i < items.length - 1) const SizedBox(height: 8),
                        ],
                        if (listState.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}
