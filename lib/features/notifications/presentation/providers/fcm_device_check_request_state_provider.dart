import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../state/fcm_device_check_request_state.dart';
import 'notification_repository_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'fcm_device_check_request_state_provider.g.dart';

@Riverpod(keepAlive: true)
class FcmDeviceCheckRequestStateNotifier
    extends _$FcmDeviceCheckRequestStateNotifier {
  @override
  FcmDeviceCheckRequestState build() => const FcmDeviceCheckRequestState();

  Future<void> checkFcmDeviceStatus({
    CancelToken? cancelToken,
    void Function()? onSuccess,
    void Function(String?)? onError,
  }) async {
    state = state.loading();

    final response = await ref
        .read(notificationRepositoryProvider)
        .checkFcmDeviceStatus(cancelToken: cancelToken);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onError?.call(error.userMessage);
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }
        onSuccess?.call();
      },
    );
  }
}
