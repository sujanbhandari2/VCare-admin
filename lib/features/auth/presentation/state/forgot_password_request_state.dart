import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';

import '../../../../shared/state/operation_state.dart';

class ForgotPasswordRequestState {
  const ForgotPasswordRequestState({
    this.operation = const OperationState<ForgotPasswordResponse>.idle(),
  });

  final OperationState<ForgotPasswordResponse> operation;
  bool get requesting => operation.isLoading;
  String? get error => operation.errorMessage;
  ForgotPasswordResponse? get response => operation.data;

  ForgotPasswordRequestState loading() => ForgotPasswordRequestState(
    operation: OperationState.loading(data: response),
  );

  ForgotPasswordRequestState failure(String? message) =>
      ForgotPasswordRequestState(operation: OperationState.failure(message));

  ForgotPasswordRequestState success(ForgotPasswordResponse data) =>
      ForgotPasswordRequestState(operation: OperationState.success(data));
}
