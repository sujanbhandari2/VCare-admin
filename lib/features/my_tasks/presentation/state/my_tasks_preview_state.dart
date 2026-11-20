import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Home preview card state for assigned open tasks.
class MyTasksPreviewState {
  const MyTasksPreviewState({
    this.operation = const OperationState<List<MyTask>>.idle(),
    this.metrics = MyTaskMetrics.empty,
    this.mutatingTaskId,
  });

  final OperationState<List<MyTask>> operation;
  final MyTaskMetrics metrics;
  final String? mutatingTaskId;

  bool get loading => operation.isLoading && items.isEmpty;
  bool get refreshing => operation.isLoading && items.isNotEmpty;
  bool get hasError => operation.hasError && items.isEmpty;
  String? get error => operation.errorMessage;
  List<MyTask> get items => operation.data ?? const [];
  int get overdueCount => metrics.overdue;
  bool get isEmpty =>
      !loading && !hasError && items.isEmpty && operation.isSuccess;

  MyTasksPreviewState loadingState() => MyTasksPreviewState(
    operation: OperationState.loading(data: items),
    metrics: metrics,
    mutatingTaskId: mutatingTaskId,
  );

  MyTasksPreviewState success(List<MyTask> data, MyTaskMetrics metrics) =>
      MyTasksPreviewState(
        operation: OperationState.success(data),
        metrics: metrics,
      );

  MyTasksPreviewState failure(String? message) => MyTasksPreviewState(
    operation: OperationState.failure(message, data: items),
    metrics: metrics,
  );

  MyTasksPreviewState copyWith({
    OperationState<List<MyTask>>? operation,
    MyTaskMetrics? metrics,
    String? mutatingTaskId,
    bool clearMutatingTaskId = false,
  }) {
    return MyTasksPreviewState(
      operation: operation ?? this.operation,
      metrics: metrics ?? this.metrics,
      mutatingTaskId: clearMutatingTaskId
          ? null
          : (mutatingTaskId ?? this.mutatingTaskId),
    );
  }
}
