import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class TaskDetailStateData {
  const TaskDetailStateData({
    this.fetchOperation = const OperationState<TaskDetail?>.idle(),
    this.updateOperation = const OperationState<TaskDetail?>.idle(),
    this.data,
  });

  final OperationState<TaskDetail?> fetchOperation;
  final OperationState<TaskDetail?> updateOperation;
  final TaskDetail? data;

  bool get fetching => fetchOperation.isLoading;

  bool get updating => updateOperation.isLoading;

  bool get isInitialLoading => fetchOperation.isLoading && data == null;

  bool get isRefreshing => fetchOperation.isLoading && data != null;

  bool get hasError => fetchOperation.hasError || updateOperation.hasError;

  String? get error =>
      updateOperation.errorMessage ?? fetchOperation.errorMessage;

  TaskDetailStateData copyWith({
    OperationState<TaskDetail?>? fetchOperation,
    OperationState<TaskDetail?>? updateOperation,
    TaskDetail? data,
  }) {
    return TaskDetailStateData(
      fetchOperation: fetchOperation ?? this.fetchOperation,
      updateOperation: updateOperation ?? this.updateOperation,
      data: data ?? this.data,
    );
  }

  TaskDetailStateData loading() => copyWith(
    fetchOperation: OperationState<TaskDetail?>.loading(data: data),
  );

  TaskDetailStateData success(TaskDetail detail) => copyWith(
    fetchOperation: OperationState<TaskDetail?>.success(detail),
    data: detail,
  );

  TaskDetailStateData failure(String? message) => copyWith(
    fetchOperation: OperationState<TaskDetail?>.failure(message, data: data),
  );

  TaskDetailStateData updatingInProgress() => copyWith(
    updateOperation: OperationState<TaskDetail?>.loading(data: data),
  );

  TaskDetailStateData updateSuccess(TaskDetail detail) => copyWith(
    updateOperation: OperationState<TaskDetail?>.success(detail),
    data: detail,
  );

  TaskDetailStateData updateFailure(String? message) => copyWith(
    updateOperation: OperationState<TaskDetail?>.failure(message, data: data),
  );
}
