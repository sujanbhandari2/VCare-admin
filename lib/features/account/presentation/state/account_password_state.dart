import 'package:vcare_admin/shared/state/operation_state.dart';

class AccountPasswordState {
  const AccountPasswordState({
    this.operation = const OperationState<void>.idle(),
  });

  final OperationState<void> operation;

  bool get saving => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  bool get succeeded => operation.isSuccess;

  AccountPasswordState loading() =>
      const AccountPasswordState(operation: OperationState.loading());

  AccountPasswordState success() =>
      const AccountPasswordState(operation: OperationState.success(null));

  AccountPasswordState failure(String? message) =>
      AccountPasswordState(operation: OperationState.failure(message));

  AccountPasswordState idle() =>
      const AccountPasswordState(operation: OperationState.idle());
}
