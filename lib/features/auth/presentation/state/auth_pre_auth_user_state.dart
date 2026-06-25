import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AuthPreAuthUserState {
  const AuthPreAuthUserState({
    this.operation = const OperationState<AuthPreAuthUser>.idle(),
  });

  final OperationState<AuthPreAuthUser> operation;

  bool get requesting => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  AuthPreAuthUser? get data => operation.data;

  AuthPreAuthUserState loading() =>
      AuthPreAuthUserState(operation: OperationState.loading(data: data));

  AuthPreAuthUserState success(AuthPreAuthUser result) =>
      AuthPreAuthUserState(operation: OperationState.success(result));

  AuthPreAuthUserState failure(String? message) =>
      AuthPreAuthUserState(operation: OperationState.failure(message, data: data));
}
