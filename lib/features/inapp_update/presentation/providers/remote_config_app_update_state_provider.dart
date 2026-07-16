import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/utils/logger.dart';
import '../../domain/entities/remote_config_app_update_info.dart';
import '../states/remote_config_app_update_state.dart';
import 'remote_config_app_update_repository_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'remote_config_app_update_state_provider.g.dart';

@Riverpod(keepAlive: true)
class RemoteConfigAppUpdateStateNotifier
    extends _$RemoteConfigAppUpdateStateNotifier {
  @override
  RemoteConfigAppUpdateState build() {
    return const RemoteConfigAppUpdateState();
  }

  Future<void> checkForUpdate({
    void Function(RemoteConfigAppUpdateInfo? info)? onCompleted,
  }) async {
    state = state.loading();

    final response = await ref
        .read(remoteConfigAppUpdateInfoRepositoryProvider)
        .fetchRemoteConfigUpdateInfo();

    response.when(
      failure: (error) {
        Logger.logError(error.message);
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (info) async {
        if (ref.mounted) {
          state = state.success(info);
        }

        onCompleted?.call(info);
      },
    );
  }
}
