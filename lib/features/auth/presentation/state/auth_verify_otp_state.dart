import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AuthVerifyOtpState {
  const AuthVerifyOtpState({
    this.operation = const OperationState<AuthVerifyOtpResult>.idle(),
  });

  final OperationState<AuthVerifyOtpResult> operation;

  bool get requesting => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  AuthVerifyOtpResult? get data => operation.data;

  AuthVerifyOtpState loading() =>
      AuthVerifyOtpState(operation: OperationState.loading(data: data));

  AuthVerifyOtpState success(AuthVerifyOtpResult result) =>
      AuthVerifyOtpState(operation: OperationState.success(result));

  AuthVerifyOtpState failure(String? message) =>
      AuthVerifyOtpState(operation: OperationState.failure(message, data: data));
}
