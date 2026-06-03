import '../../../../shared/state/operation_state.dart';

class FcmDeviceAddOrUpdateRequestState {
  const FcmDeviceAddOrUpdateRequestState({
    this.operation = const OperationState<bool>.idle(),
  });

  final OperationState<bool> operation;

  bool get requesting => operation.isLoading;

  String? get error => operation.errorMessage;

  bool get success => operation.isSuccess;

  FcmDeviceAddOrUpdateRequestState loading() =>
      FcmDeviceAddOrUpdateRequestState(
        operation: const OperationState.loading(),
      );

  FcmDeviceAddOrUpdateRequestState failure(String? message) =>
      FcmDeviceAddOrUpdateRequestState(
        operation: OperationState.failure(message),
      );

  FcmDeviceAddOrUpdateRequestState successState() =>
      FcmDeviceAddOrUpdateRequestState(
        operation: const OperationState.success(true),
      );
}
