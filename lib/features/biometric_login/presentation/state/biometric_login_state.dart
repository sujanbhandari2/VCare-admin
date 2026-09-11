import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';

class BiometricLoginState {
  const BiometricLoginState({
    this.statusOperation = const OperationState<BiometricLoginStatus>.idle(),
    this.actionOperation = const OperationState<void>.idle(),
  });

  final OperationState<BiometricLoginStatus> statusOperation;
  final OperationState<void> actionOperation;

  bool get fetching => statusOperation.isLoading;
  bool get acting => actionOperation.isLoading;
  bool get loading => fetching || acting;
  bool get hasError => statusOperation.hasError || actionOperation.hasError;
  String? get error =>
      actionOperation.errorMessage ?? statusOperation.errorMessage;
  BiometricLoginStatus? get status => statusOperation.data;
  bool get isActive => status?.isEnrolled == true;

  BiometricLoginState copyWith({
    OperationState<BiometricLoginStatus>? statusOperation,
    OperationState<void>? actionOperation,
  }) {
    return BiometricLoginState(
      statusOperation: statusOperation ?? this.statusOperation,
      actionOperation: actionOperation ?? this.actionOperation,
    );
  }

  BiometricLoginState loadingStatus({BiometricLoginStatus? data}) {
    return copyWith(
      statusOperation: OperationState.loading(data: data ?? status),
    );
  }

  BiometricLoginState statusSuccess(BiometricLoginStatus status) {
    return copyWith(
      statusOperation: OperationState.success(status),
    );
  }

  BiometricLoginState statusFailure(String? message) {
    return copyWith(
      statusOperation: OperationState.failure(message, data: status),
    );
  }

  BiometricLoginState actionLoading() {
    return copyWith(
      actionOperation: OperationState.loading(data: actionOperation.data),
    );
  }

  BiometricLoginState actionSuccess() {
    return copyWith(
      actionOperation: const OperationState<void>.success(null),
    );
  }

  BiometricLoginState actionFailure(String? message) {
    return copyWith(
      actionOperation: OperationState.failure(message),
    );
  }

  BiometricLoginState clearAction() {
    return copyWith(
      actionOperation: const OperationState<void>.idle(),
    );
  }
}
