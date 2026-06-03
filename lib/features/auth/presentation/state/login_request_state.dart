import 'package:flutter_template/features/auth/domain/enums/login_request_type.dart';
import 'package:flutter_template/features/auth/domain/entities/auth_session.dart';

import '../../../../shared/state/operation_state.dart';

class LoginRequestState {
  const LoginRequestState({
    this.type,
    this.operation = const OperationState<AuthSession>.idle(),
  });

  final LoginRequestType? type;
  final OperationState<AuthSession> operation;
  bool get requesting => operation.isLoading;
  String? get error => operation.errorMessage;
  AuthSession? get response => operation.data;

  LoginRequestState loading({required LoginRequestType type}) =>
      LoginRequestState(
        type: type,
        operation: OperationState.loading(data: response),
      );

  LoginRequestState failure(String? message) =>
      LoginRequestState(type: type, operation: OperationState.failure(message));

  LoginRequestState success(AuthSession data) =>
      LoginRequestState(type: type, operation: OperationState.success(data));
}
