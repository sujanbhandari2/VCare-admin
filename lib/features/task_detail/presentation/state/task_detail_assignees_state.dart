import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class TaskDetailAssigneesStateData {
  const TaskDetailAssigneesStateData({
    this.operation = const OperationState<List<AssociatedUser>>.idle(),
  });

  final OperationState<List<AssociatedUser>> operation;

  List<AssociatedUser> get assignees => operation.data ?? const [];

  bool get fetching => operation.isLoading;

  String? get error => operation.errorMessage;

  TaskDetailAssigneesStateData loading() => TaskDetailAssigneesStateData(
    operation: OperationState<List<AssociatedUser>>.loading(
      data: operation.data,
    ),
  );

  TaskDetailAssigneesStateData success(List<AssociatedUser> users) =>
      TaskDetailAssigneesStateData(
        operation: OperationState<List<AssociatedUser>>.success(users),
      );

  TaskDetailAssigneesStateData failure(String? message) =>
      TaskDetailAssigneesStateData(
        operation: OperationState<List<AssociatedUser>>.failure(
          message,
          data: operation.data,
        ),
      );
}
