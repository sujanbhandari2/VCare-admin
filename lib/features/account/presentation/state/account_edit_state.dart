import 'package:vcare_admin/features/account/domain/entities/updated_account_user.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AccountEditState {
  const AccountEditState({
    this.operation = const OperationState<UpdatedAccountUser>.idle(),
  });

  final OperationState<UpdatedAccountUser> operation;

  bool get saving => operation.isLoading;
  bool get hasError => operation.hasError;
  String? get error => operation.errorMessage;
  UpdatedAccountUser? get data => operation.data;

  AccountEditState loading() =>
      AccountEditState(operation: OperationState.loading(data: data));

  AccountEditState success(UpdatedAccountUser data) =>
      AccountEditState(operation: OperationState.success(data));

  AccountEditState failure(String? message) => AccountEditState(
        operation: OperationState.failure(message, data: data),
      );

  AccountEditState idle() =>
      const AccountEditState(operation: OperationState.idle());
}
