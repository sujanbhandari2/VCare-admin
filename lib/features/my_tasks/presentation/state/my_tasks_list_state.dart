import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/shared/state/loadable_list_state.dart';

/// Filter + list state for the My Tasks queue screen.
class MyTasksListState {
  MyTasksListState({
    LoadableListState<MyTask>? list,
    this.metrics = MyTaskMetrics.empty,
    this.ownerFilter = MyTaskOwnerFilter.me,
    this.quickFilters = const {},
    this.statusFilter = MyTaskStatus.toDo,
    this.priorityFilter,
    this.categoryFilter = MyTaskQueueCategoryFilter.all,
    this.originFilter,
    this.searchQuery = '',
    this.mutatingTaskId,
  }) : list = list ?? LoadableListState<MyTask>();

  final LoadableListState<MyTask> list;
  final MyTaskMetrics metrics;
  final MyTaskOwnerFilter ownerFilter;
  final Set<MyTaskQuickFilter> quickFilters;
  final MyTaskStatus? statusFilter;
  final MyTaskPriority? priorityFilter;
  final MyTaskQueueCategoryFilter categoryFilter;
  final MyTaskOrigin? originFilter;
  final String searchQuery;
  final String? mutatingTaskId;

  List<MyTask> get items => list.items;
  bool get isInitialLoading => list.isInitialLoading;
  bool get isRefreshing => list.isRefreshing;
  bool get isLoadingMore => list.isLoadingMore;
  bool get isInitialError => list.isInitialError;
  bool get isEmpty => list.isEmpty;
  bool get hasMore => list.hasMore;
  int get totalItems => list.totalItems;
  String? get errorMessage => list.operation.errorMessage;
  String? get loadMoreErrorMessage => list.loadMoreErrorMessage;

  bool get hasActiveAdvancedFilters =>
      categoryFilter != MyTaskQueueCategoryFilter.all ||
      statusFilter != MyTaskStatus.toDo ||
      originFilter != null ||
      priorityFilter != null;

  bool get hasOverdueQuickFilter =>
      quickFilters.contains(MyTaskQuickFilter.overdue);

  bool get hasSnoozedQuickFilter =>
      quickFilters.contains(MyTaskQuickFilter.snoozed);

  MyTasksListState copyWith({
    LoadableListState<MyTask>? list,
    MyTaskMetrics? metrics,
    MyTaskOwnerFilter? ownerFilter,
    Set<MyTaskQuickFilter>? quickFilters,
    MyTaskStatus? statusFilter,
    bool clearStatusFilter = false,
    MyTaskPriority? priorityFilter,
    bool clearPriorityFilter = false,
    MyTaskQueueCategoryFilter? categoryFilter,
    MyTaskOrigin? originFilter,
    bool clearOriginFilter = false,
    String? searchQuery,
    String? mutatingTaskId,
    bool clearMutatingTaskId = false,
  }) {
    return MyTasksListState(
      list: list ?? this.list,
      metrics: metrics ?? this.metrics,
      ownerFilter: ownerFilter ?? this.ownerFilter,
      quickFilters: quickFilters ?? this.quickFilters,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      priorityFilter: clearPriorityFilter
          ? null
          : (priorityFilter ?? this.priorityFilter),
      categoryFilter: categoryFilter ?? this.categoryFilter,
      originFilter: clearOriginFilter
          ? null
          : (originFilter ?? this.originFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      mutatingTaskId: clearMutatingTaskId
          ? null
          : (mutatingTaskId ?? this.mutatingTaskId),
    );
  }
}
