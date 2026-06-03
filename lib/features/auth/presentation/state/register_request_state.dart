import 'package:flutter_template/features/auth/domain/entities/register_response.dart';

import '../../../../shared/state/operation_state.dart';

class RegisterRequestState {
  const RegisterRequestState({
    this.operation = const OperationState<RegisterResponse>.idle(),
    this.payloads = const {},
    this.files = const {},
  });

  final OperationState<RegisterResponse> operation;
  final Map<String, dynamic> payloads; // To store register screen fields data
  final Map<String, dynamic> files; // To store register screen image field data
  bool get requesting => operation.isLoading;
  String? get error => operation.errorMessage;
  RegisterResponse? get response => operation.data;

  RegisterRequestState loading() => RegisterRequestState(
    operation: OperationState.loading(data: response),
    payloads: payloads,
    files: files,
  );

  RegisterRequestState failure(String? message) => RegisterRequestState(
    operation: OperationState.failure(message, data: response),
    payloads: payloads,
    files: files,
  );

  RegisterRequestState success(
    RegisterResponse data, {
    Map<String, dynamic> payloads = const {},
    Map<String, dynamic> files = const {},
  }) => RegisterRequestState(
    operation: OperationState.success(data),
    payloads: payloads,
    files: files,
  );
}
