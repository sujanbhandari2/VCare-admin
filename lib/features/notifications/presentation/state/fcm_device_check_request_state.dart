import '../../../../shared/state/operation_state.dart';
import '../../domain/entities/fcm_device_check_response.dart';

class FcmDeviceCheckRequestState {
  const FcmDeviceCheckRequestState({
    this.operation = const OperationState<FcmDeviceCheckResponse?>.idle(),
  });

  final OperationState<FcmDeviceCheckResponse?> operation;

  bool get requesting => operation.isLoading;
  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  FcmDeviceCheckResponse? get data => operation.data;

  FcmDeviceCheckRequestState loading() => FcmDeviceCheckRequestState(
    operation: OperationState.loading(data: data),
  );

  FcmDeviceCheckRequestState failure(String? message) =>
      FcmDeviceCheckRequestState(
        operation: OperationState.failure(message, data: data),
      );

  FcmDeviceCheckRequestState success(FcmDeviceCheckResponse? data) =>
      FcmDeviceCheckRequestState(
        operation: OperationState.success(data),
      );
}
