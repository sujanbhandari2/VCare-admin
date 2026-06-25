import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class AuthMeState {
  const AuthMeState({
    this.operation = const OperationState<AuthMe>.idle(),
    this.data,
  });

  final OperationState<AuthMe> operation;
  final AuthMe? data;

  bool get fetching => operation.isLoading;

  String? get error => operation.errorMessage;

  AuthMeUser? get user => data?.user;

  List<String> get menu => data?.menu ?? const [];

  String? get firstName => user?.firstName;

  AuthMeState loading() => AuthMeState(
        operation: OperationState.loading(data: data),
        data: data,
      );

  AuthMeState success(AuthMe authMe) => AuthMeState(
        operation: OperationState.success(authMe),
        data: authMe,
      );

  AuthMeState failure(String? message) => AuthMeState(
        operation: OperationState.failure(message, data: data),
        data: data,
      );
}
