import 'package:vcare_admin/features/auth/domain/entities/reset_password_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class ResetPasswordState {
  const ResetPasswordState({
    this.operation = const OperationState<ResetPasswordResult>.idle(),
    this.success = false,
  });

  final OperationState<ResetPasswordResult> operation;
  final bool success;

  bool get resetting => operation.isLoading;

  ResetPasswordState loading() => ResetPasswordState(
    operation: OperationState.loading(),
    success: success,
  );

  ResetPasswordState failure(String? message) => ResetPasswordState(
    operation: OperationState.failure(message),
    success: success,
  );

  ResetPasswordState completed(ResetPasswordResult data) => ResetPasswordState(
    operation: OperationState.success(data),
    success: true,
  );
}
