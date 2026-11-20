import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/feature_access/presentation/widgets/feature_access_gate.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_list_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_create_edit_sheet.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_detail_sheet.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_task_row.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_tasks_empty_state.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_tasks_filter_sheet.dart';
import 'package:vcare_admin/features/my_tasks/presentation/widgets/my_tasks_toolbar.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_assignees_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

class MyTasksScreen extends ConsumerStatefulWidget {
  const MyTasksScreen({super.key});

  @override
  ConsumerState<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends ConsumerState<MyTasksScreen> {
  static const double _loadMoreTriggerThreshold = 240;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isLoadMoreRequested = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(myTasksListStateProvider);
      final notifier = ref.read(myTasksListStateProvider.notifier);
      if (state.items.isEmpty && !state.isInitialLoading) {
        notifier.loadInitial();
      } else {
        notifier.refresh();
      }
      if (ref.read(taskDetailAssigneesStateProvider).assignees.isEmpty) {
        ref.read(taskDetailAssigneesStateProvider.notifier).fetchAssignees();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final listState = ref.read(myTasksListStateProvider);
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
      ref.read(myTasksListStateProvider.notifier).loadMore().whenComplete(() {
        if (mounted) _isLoadMoreRequested = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(myTasksListStateProvider.notifier).search(value);
    });
  }

  Future<void> _openFilters() async {
    final state = ref.read(myTasksListStateProvider);
    final result = await MyTasksFilterSheet.show(
      context,
      categoryFilter: state.categoryFilter,
      statusFilter: state.statusFilter,
      originFilter: state.originFilter,
      priorityFilter: state.priorityFilter,
    );
    if (result == null || !mounted) return;

    final notifier = ref.read(myTasksListStateProvider.notifier);
    if (result.clear) {
      await notifier.clearAdvancedFilters();
      return;
    }

    await notifier.setCategoryFilter(result.categoryFilter);
    await notifier.setStatusFilter(result.statusFilter);
    await notifier.setOriginFilter(result.originFilter);
    await notifier.setPriorityFilter(result.priorityFilter);
  }

  Future<void> _openCreate() async {
    final created = await MyTaskCreateEditSheet.show(context);
    if (created == true && mounted) {
      await ref.read(myTasksListStateProvider.notifier).refresh();
    }
  }

  Future<void> _openTask(String taskId) async {
    final changed = await MyTaskDetailSheet.show(context, taskId: taskId);
    if (changed == true && mounted) {
      await ref.read(myTasksListStateProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(adminAuthSessionProvider).menu;
    final l10n = context.appLocalization;

    return Scaffold(
      body: FeatureAccessGate(
        isEnabled: (access) =>
            access.taskManagement && (menu.isEmpty || menu.contains('tasks')),
        deniedTitle: l10n.my_tasks_unavailable_title,
        deniedMessage: l10n.my_tasks_unavailable_message,
        deniedIcon: LucideIcons.listTodo,
        child: _buildBody(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: Text(l10n.my_tasks_new_task),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final listState = ref.watch(myTasksListStateProvider);
    final assignees = ref.watch(taskDetailAssigneesStateProvider).assignees;
    final currentUserId = ref.watch(adminAuthSessionProvider).user?.id;
    final vcare = context.vcare;
    final l10n = context.appLocalization;

    return VcareRefreshScrollView(
      onRefresh: () => ref.read(myTasksListStateProvider.notifier).refresh(),
      controller: _scrollController,
      slivers: [
        SliverVcarePageHeader(title: l10n.my_tasks_title, showBack: true),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: MyTasksToolbar(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onOpenAdvancedFilters: _openFilters,
              hasAdvancedFilters: listState.hasActiveAdvancedFilters,
              hasOverdueQuickFilter: listState.hasOverdueQuickFilter,
              hasSnoozedQuickFilter: listState.hasSnoozedQuickFilter,
              ownerFilter: listState.ownerFilter,
              currentUserId: currentUserId,
              currentUserName: ref
                  .watch(adminAuthSessionProvider)
                  .user
                  ?.displayName,
              assignees: assignees,
              onToggleQuickFilter: (filter) => ref
                  .read(myTasksListStateProvider.notifier)
                  .toggleQuickFilter(filter),
              onOwnerFilterChanged: (filter) => ref
                  .read(myTasksListStateProvider.notifier)
                  .setOwnerFilter(filter),
            ),
          ),
        ),
        SliverPadding(
          padding: context.mobileShellScrollPadding,
          sliver: listState.isInitialLoading && listState.items.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              : listState.isInitialError && listState.items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: VcareErrorStatePanel(
                    title: l10n.my_tasks_unable_to_load,
                    message: listState.errorMessage,
                    actionLabel: l10n.retry,
                    onAction: () => ref
                        .read(myTasksListStateProvider.notifier)
                        .loadInitial(forceRefresh: true),
                  ),
                )
              : SliverList(
                  delegate: SliverChildListDelegate([
                    if (listState.items.isEmpty)
                      MyTasksEmptyState(
                        hasSearch:
                            listState.searchQuery.isNotEmpty ||
                            listState.hasActiveAdvancedFilters ||
                            listState.quickFilters.isNotEmpty,
                      )
                    else ...[
                      Text(
                        l10n.my_tasks_showing_count(
                          listState.items.length,
                          listState.totalItems,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: vcare.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < listState.items.length; i++) ...[
                        MyTaskRow(
                          task: listState.items[i],
                          onTap: () => _openTask(listState.items[i].id),
                        ),
                        if (i < listState.items.length - 1)
                          const SizedBox(height: 10),
                      ],
                      if (listState.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 72),
                  ]),
                ),
        ),
      ],
    );
  }
}
