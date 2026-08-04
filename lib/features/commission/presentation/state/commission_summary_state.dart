import 'package:vcare_admin/features/commission/domain/entities/commission_summary.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class CommissionSummaryState {
  const CommissionSummaryState({
    this.operation = const OperationState<CommissionSummary>.idle(),
    this.data,
  });

  final OperationState<CommissionSummary> operation;
  final CommissionSummary? data;

  bool get fetching => operation.isLoading;

  String? get error => operation.errorMessage;

  CommissionSummaryState loading() => CommissionSummaryState(
    operation: OperationState.loading(data: data),
    data: data,
  );

  CommissionSummaryState success(CommissionSummary summary) =>
      CommissionSummaryState(
        operation: OperationState.success(summary),
        data: summary,
      );

  CommissionSummaryState failure(String? message) => CommissionSummaryState(
    operation: OperationState.failure(message, data: data),
    data: data,
  );
}
