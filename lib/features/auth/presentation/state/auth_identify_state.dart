import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AuthIdentifyState {
  const AuthIdentifyState({
    this.operation = const OperationState<AuthIdentifyResult>.idle(),
    this.lastResult,
  });

  final OperationState<AuthIdentifyResult> operation;
  final AuthIdentifyResult? lastResult;

  bool get requesting => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;

  AuthIdentifyState loading() => AuthIdentifyState(
        operation: OperationState.loading(data: lastResult),
        lastResult: lastResult,
      );

  AuthIdentifyState success(AuthIdentifyResult result) => AuthIdentifyState(
        operation: OperationState.success(result),
        lastResult: result,
      );

  AuthIdentifyState failure(String? message) => AuthIdentifyState(
        operation: OperationState.failure(message, data: lastResult),
        lastResult: lastResult,
      );

  AuthIdentifyState cleared() => const AuthIdentifyState();
}

class AuthRequestOtpState {
  const AuthRequestOtpState({
    this.operation = const OperationState<void>.idle(),
  });

  final OperationState<void> operation;

  bool get requesting => operation.isLoading;
  String? get error => operation.errorMessage;

  AuthRequestOtpState loading() =>
      AuthRequestOtpState(operation: const OperationState.loading());

  AuthRequestOtpState success() =>
      const AuthRequestOtpState(operation: OperationState.success(null));

  AuthRequestOtpState failure(String? message) =>
      AuthRequestOtpState(operation: OperationState.failure(message));
}
