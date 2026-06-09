import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/storage/storage_keys.dart';
import '../../../../core/services/storage/storage_service_provider.dart';
import '../../../../shared/utils/logger.dart';
import '../state/fcm_device_add_or_update_request_state.dart';
import 'notification_repository_provider.dart';

part 'fcm_device_add_or_update_request_state_provider.g.dart';

/// FcmDeviceAddOrUpdateRequestStateNotifier
///
@Riverpod(keepAlive: true)
class FcmDeviceAddOrUpdateRequestStateNotifier
    extends _$FcmDeviceAddOrUpdateRequestStateNotifier {
  @override
  FcmDeviceAddOrUpdateRequestState build() =>
      const FcmDeviceAddOrUpdateRequestState();

  /// Method to register or update fcm device
  ///
  Future<void> registerOrUpdateFcmDevice({
    required String token,
    CancelToken? cancelToken,
    void Function()? onSuccess,
    void Function(String?)? onError,
  }) async {
    if (kIsWeb) return;

    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      Logger.logMessage('[FCM] Token empty. Skipping device registration.');
      onError?.call('[FCM] Token empty. Skipping device registration.');
      return;
    }

    final storageService = ref.read(storageServiceProvider);
    final accessToken =
        storageService.get(StorageKeys.loggedInUserToken)?.toString() ?? '';
    if (accessToken.trim().isEmpty) {
      Logger.logMessage(
        '[FCM] User not authenticated. Skipping device token register.',
      );
      onError?.call(
        '[FCM] User not authenticated. Skipping device token register.',
      );
      return;
    }

    state = state.loading();

    final payloads = <String, dynamic>{
      'fcmToken': trimmedToken,
      'fcmPlatform': Platform.isIOS ? 'IOS' : 'ANDROID',
    };

    final response = await ref
        .read(notificationRepositoryProvider)
        .registerDeviceToken(payloads: payloads, cancelToken: cancelToken);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
        onError?.call(error.message);
      },
      success: (_) {
        if (ref.mounted) {
          state = state.successState();
        }
        onSuccess?.call();
      },
    );
  }
}
