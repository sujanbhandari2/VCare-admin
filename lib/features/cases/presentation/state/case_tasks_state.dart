import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

/// Tasks list + mutation state for a single case.
class CaseTasksStateData {
  const CaseTasksStateData({
    this.fetchOperation = const OperationState<List<CaseTask>>.idle(),
    this.mutationOperation = const OperationState<void>.idle(),
  });

  final OperationState<List<CaseTask>> fetchOperation;
  final OperationState<void> mutationOperation;

  List<CaseTask> get tasks => fetchOperation.data ?? const [];

  bool get fetching => fetchOperation.isLoading;

  bool get mutating => mutationOperation.isLoading;

  bool get isInitialLoading => fetchOperation.isLoading && tasks.isEmpty;

  bool get isRefreshing => fetchOperation.isLoading && tasks.isNotEmpty;

  int get completedCount =>
      tasks.where((task) => task.status == CaseTaskStatus.completed).length;

  String? get error =>
      mutationOperation.errorMessage ?? fetchOperation.errorMessage;

  CaseTasksStateData copyWith({
    OperationState<List<CaseTask>>? fetchOperation,
    OperationState<void>? mutationOperation,
  }) {
    return CaseTasksStateData(
      fetchOperation: fetchOperation ?? this.fetchOperation,
      mutationOperation: mutationOperation ?? this.mutationOperation,
    );
  }

  CaseTasksStateData loading() => copyWith(
    fetchOperation: OperationState<List<CaseTask>>.loading(data: tasks),
  );

  CaseTasksStateData success(List<CaseTask> tasks) => copyWith(
    fetchOperation: OperationState<List<CaseTask>>.success(tasks),
  );

  CaseTasksStateData failure(String? message) => copyWith(
    fetchOperation: OperationState<List<CaseTask>>.failure(
      message,
      data: tasks,
    ),
  );

  CaseTasksStateData mutationLoading() =>
      copyWith(mutationOperation: const OperationState<void>.loading());

  CaseTasksStateData mutationIdle() =>
      copyWith(mutationOperation: const OperationState<void>.idle());

  CaseTasksStateData mutationFailure(String? message) => copyWith(
    mutationOperation: OperationState<void>.failure(message),
  );
}
