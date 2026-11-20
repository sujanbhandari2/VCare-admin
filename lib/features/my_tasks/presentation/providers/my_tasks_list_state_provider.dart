import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/admin_dashboard/presentation/providers/admin_dashboard_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_repository_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_preview_state_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/state/my_tasks_list_state.dart';
import 'package:vcare_admin/features/my_tasks/utils/my_task_formatters.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'my_tasks_list_state_provider.g.dart';

@Riverpod(keepAlive: true)
class MyTasksListStateNotifier extends _$MyTasksListStateNotifier {
  int _currentPage = 0;
  int _requestGeneration = 0;

  @override
  MyTasksListState build() => MyTasksListState();

  String? get _currentUserId =>
      ref.read(adminAuthSessionProvider).user?.id.trim();

  bool get _forceRefresh => ref.read(networkFetchSessionProvider);

  MyTaskListRequest _buildRequest({required int page}) {
    return buildMyTaskListRequest(
      page: page,
      limit: myTasksPageSize,
      currentUserId: _currentUserId,
      ownerFilter: state.ownerFilter,
      quickFilters: state.quickFilters,
      statusFilter: state.statusFilter,
      priorityFilter: state.priorityFilter,
      categoryFilter: state.categoryFilter,
      originFilter: state.originFilter,
      search: state.searchQuery,
    );
  }

  Future<void> loadInitial({bool? forceRefresh}) async {
    final generation = ++_requestGeneration;
    final shouldForce = forceRefresh ?? _forceRefresh;

    if (ref.mounted) {
      state = state.copyWith(list: state.list.loading());
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .fetchTasks(_buildRequest(page: 1), forceRefresh: shouldForce);

    if (!ref.mounted || generation != _requestGeneration) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _requestGeneration) {
          state = state.copyWith(list: state.list.failure(error.userMessage));
        }
      },
      success: (page) {
        if (!ref.mounted || generation != _requestGeneration) return;
        _currentPage = 1;
        var items = page.items;
        if (state.ownerFilter is MyTaskOwnerFilterUnassigned) {
          items = items
              .where((task) => task.assignee == null)
              .toList(growable: false);
        }
        state = state.copyWith(
          list: state.list.success(items: items, total: page.totalCount),
          metrics: page.metrics,
        );
      },
    );
  }

  Future<void> refresh() => loadInitial(forceRefresh: true);

  Future<void> syncAfterMutation() async {
    await Future.wait([
      refresh(),
      ref.read(myTasksPreviewStateProvider.notifier).refresh(),
      ref.read(adminDashboardStateProvider.notifier).load(forceRefresh: true),
    ]);
  }

  Future<void> search(String query) async {
    if (!ref.mounted) return;
    state = state.copyWith(searchQuery: query.trim());
    await loadInitial(forceRefresh: true);
  }

  Future<void> setOwnerFilter(MyTaskOwnerFilter filter) async {
    if (!ref.mounted) return;
    state = state.copyWith(ownerFilter: filter);
    await loadInitial(forceRefresh: true);
  }

  Future<void> toggleQuickFilter(MyTaskQuickFilter filter) async {
    if (!ref.mounted) return;
    final next = Set<MyTaskQuickFilter>.from(state.quickFilters);
    if (next.contains(filter)) {
      next.remove(filter);
    } else {
      next.add(filter);
      if (filter == MyTaskQuickFilter.snoozed) {
        next.remove(MyTaskQuickFilter.overdue);
      }
      if (filter == MyTaskQuickFilter.overdue) {
        next.remove(MyTaskQuickFilter.snoozed);
      }
    }
    state = state.copyWith(quickFilters: next);
    await loadInitial(forceRefresh: true);
  }

  Future<void> setStatusFilter(MyTaskStatus? status) async {
    if (!ref.mounted) return;
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadInitial(forceRefresh: true);
  }

  Future<void> setPriorityFilter(MyTaskPriority? priority) async {
    if (!ref.mounted) return;
    state = state.copyWith(
      priorityFilter: priority,
      clearPriorityFilter: priority == null,
    );
    await loadInitial(forceRefresh: true);
  }

  Future<void> setCategoryFilter(MyTaskQueueCategoryFilter category) async {
    if (!ref.mounted) return;
    state = state.copyWith(categoryFilter: category);
    await loadInitial(forceRefresh: true);
  }

  Future<void> setOriginFilter(MyTaskOrigin? origin) async {
    if (!ref.mounted) return;
    state = state.copyWith(
      originFilter: origin,
      clearOriginFilter: origin == null,
    );
    await loadInitial(forceRefresh: true);
  }

  Future<void> clearAdvancedFilters() async {
    if (!ref.mounted) return;
    state = state.copyWith(
      categoryFilter: MyTaskQueueCategoryFilter.all,
      statusFilter: MyTaskStatus.toDo,
      clearOriginFilter: true,
      clearPriorityFilter: true,
    );
    await loadInitial(forceRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.isInitialLoading ||
        state.isInitialError) {
      return;
    }

    final generation = _requestGeneration;
    if (ref.mounted) {
      state = state.copyWith(list: state.list.loadingMore());
    }

    final nextPage = _currentPage + 1;
    final response = await ref
        .read(myTaskRepositoryProvider)
        .fetchTasks(_buildRequest(page: nextPage), forceRefresh: true);

    if (!ref.mounted || generation != _requestGeneration) return;

    response.when(
      failure: (error) {
        if (ref.mounted && generation == _requestGeneration) {
          state = state.copyWith(
            list: state.list.appendFailure(error.userMessage),
          );
        }
      },
      success: (page) {
        if (!ref.mounted || generation != _requestGeneration) return;
        _currentPage = nextPage;
        var items = page.items;
        if (state.ownerFilter is MyTaskOwnerFilterUnassigned) {
          items = items
              .where((task) => task.assignee == null)
              .toList(growable: false);
        }
        state = state.copyWith(
          list: state.list.appendSuccess(
            appendedItems: items,
            total: page.totalCount,
          ),
          metrics: page.metrics,
        );
      },
    );
  }

  Future<bool> completeTask({
    required String taskId,
    void Function(String? error)? onError,
  }) async {
    if (state.mutatingTaskId != null) return false;
    if (ref.mounted) {
      state = state.copyWith(mutatingTaskId: taskId);
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .updateTask(
          taskId: taskId,
          request: const MyTaskUpdateRequest(status: MyTaskStatus.done),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        await syncAfterMutation();
        return true;
      },
    );
  }

  Future<bool> reopenTask({
    required String taskId,
    void Function(String? error)? onError,
  }) async {
    if (state.mutatingTaskId != null) return false;
    if (ref.mounted) {
      state = state.copyWith(mutatingTaskId: taskId);
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .updateTask(
          taskId: taskId,
          request: const MyTaskUpdateRequest(status: MyTaskStatus.toDo),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        await syncAfterMutation();
        return true;
      },
    );
  }

  Future<bool> deleteTask({
    required String taskId,
    void Function(String? error)? onError,
  }) async {
    if (state.mutatingTaskId != null) return false;
    if (ref.mounted) {
      state = state.copyWith(mutatingTaskId: taskId);
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .deleteTask(taskId: taskId);

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        await syncAfterMutation();
        return true;
      },
    );
  }

  Future<bool> snoozeTask({
    required String taskId,
    required DateTime until,
    String? notes,
    void Function(String? error)? onError,
  }) async {
    if (state.mutatingTaskId != null) return false;
    if (ref.mounted) {
      state = state.copyWith(mutatingTaskId: taskId);
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .snoozeTask(
          taskId: taskId,
          request: MyTaskSnoozeRequest(
            snoozedTillIso: until.toUtc().toIso8601String(),
            notes: notes,
          ),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        await syncAfterMutation();
        return true;
      },
    );
  }

  Future<bool> resumeTask({
    required String taskId,
    void Function(String? error)? onError,
  }) async {
    if (state.mutatingTaskId != null) return false;
    if (ref.mounted) {
      state = state.copyWith(mutatingTaskId: taskId);
    }

    final response = await ref
        .read(myTaskRepositoryProvider)
        .snoozeTask(
          taskId: taskId,
          request: const MyTaskSnoozeRequest(snoozedTillIso: null),
        );

    return response.when(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        onError?.call(error.userMessage);
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.copyWith(clearMutatingTaskId: true);
        }
        await syncAfterMutation();
        return true;
      },
    );
  }
}
