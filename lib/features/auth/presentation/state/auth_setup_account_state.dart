import 'package:vcare_admin/features/auth/domain/entities/auth_setup_account_result.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AuthSetupAccountState {
  const AuthSetupAccountState({
    this.operation = const OperationState<AuthSetupAccountResult>.idle(),
  });

  final OperationState<AuthSetupAccountResult> operation;

  bool get requesting => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  AuthSetupAccountResult? get data => operation.data;

  AuthSetupAccountState loading() =>
      AuthSetupAccountState(operation: OperationState.loading(data: data));

  AuthSetupAccountState success(AuthSetupAccountResult result) =>
      AuthSetupAccountState(operation: OperationState.success(result));

  AuthSetupAccountState failure(String? message) =>
      AuthSetupAccountState(operation: OperationState.failure(message, data: data));
}
