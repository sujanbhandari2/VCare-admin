import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AuthMeState {
  const AuthMeState({
    this.fetchOperation = const OperationState<AuthMe>.idle(),
    this.updateOperation = const OperationState<void>.idle(),
    this.data,
  });

  final OperationState<AuthMe> fetchOperation;
  final OperationState<void> updateOperation;
  final AuthMe? data;

  bool get fetching => fetchOperation.isLoading;

  bool get updating => updateOperation.isLoading;

  String? get error =>
      updateOperation.errorMessage ?? fetchOperation.errorMessage;

  AuthMeUser? get user => data?.user;

  List<String> get menu => data?.menu ?? const [];

  String? get firstName => user?.firstName;

  /// Backward-compatible alias used by existing callers.
  OperationState<AuthMe> get operation => fetchOperation;

  AuthMeState loading() => AuthMeState(
        fetchOperation: OperationState.loading(data: data),
        updateOperation: updateOperation,
        data: data,
      );

  AuthMeState success(AuthMe authMe) => AuthMeState(
        fetchOperation: OperationState.success(authMe),
        updateOperation: updateOperation,
        data: authMe,
      );

  AuthMeState failure(String? message) => AuthMeState(
        fetchOperation: OperationState.failure(message, data: data),
        updateOperation: updateOperation,
        data: data,
      );

  AuthMeState updatingInProgress() => AuthMeState(
        fetchOperation: fetchOperation,
        updateOperation: const OperationState.loading(),
        data: data,
      );

  AuthMeState updateSuccess() => AuthMeState(
        fetchOperation: fetchOperation,
        updateOperation: const OperationState.success(null),
        data: data,
      );

  AuthMeState updateFailure(String? message) => AuthMeState(
        fetchOperation: fetchOperation,
        updateOperation: OperationState.failure(message),
        data: data,
      );
}
