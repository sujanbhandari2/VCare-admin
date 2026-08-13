import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class ForgotPasswordRequestState {
  const ForgotPasswordRequestState({
    this.operation = const OperationState<ForgotPasswordResult>.idle(),
  });

  final OperationState<ForgotPasswordResult> operation;

  bool get requesting => operation.isLoading;
  ForgotPasswordResult? get result => operation.data;

  ForgotPasswordRequestState loading() => ForgotPasswordRequestState(
    operation: OperationState.loading(data: result),
  );

  ForgotPasswordRequestState failure(String? message) =>
      ForgotPasswordRequestState(operation: OperationState.failure(message));

  ForgotPasswordRequestState success(ForgotPasswordResult data) =>
      ForgotPasswordRequestState(operation: OperationState.success(data));
}
