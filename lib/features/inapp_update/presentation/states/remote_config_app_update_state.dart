import '../../../../shared/state/operation_state.dart';
import '../../domain/entities/remote_config_app_update_info.dart';

class RemoteConfigAppUpdateState {
  const RemoteConfigAppUpdateState({
    this.operation = const OperationState<RemoteConfigAppUpdateInfo?>.idle(),
  });

  final OperationState<RemoteConfigAppUpdateInfo?> operation;

  bool get requesting => operation.isLoading;

  bool get hasError => operation.hasError;

  String? get error => operation.errorMessage;

  RemoteConfigAppUpdateInfo? get info => operation.data;

  bool get hasUpdate =>
      operation.isSuccess && info != null && info!.isUpdateAvailable;

  bool get isUpToDate => info?.latestVersion == info?.currentVersion;

  RemoteConfigAppUpdateState loading() =>
      RemoteConfigAppUpdateState(operation: OperationState.loading(data: info));

  RemoteConfigAppUpdateState success(RemoteConfigAppUpdateInfo? info) =>
      RemoteConfigAppUpdateState(operation: OperationState.success(info));

  RemoteConfigAppUpdateState failure(String? message) =>
      RemoteConfigAppUpdateState(
        operation: OperationState.failure(message, data: info),
      );
}
