import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_template/core/services/firebase/firebase_notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/storage/storage_keys.dart';
import '../../../../core/services/storage/storage_service_provider.dart';
import '../../../../shared/utils/logger.dart';
import '../../../auth/presentation/providers/logged_in_user_id_provider.dart';
import 'fcm_device_add_or_update_request_state_provider.dart';

part 'fcm_notification_init_provider.g.dart';

@Riverpod(keepAlive: true)
class FcmNotificationInitNotifier extends _$FcmNotificationInitNotifier {
  late FirebaseNotificationService _notificationService;

  @override
  Future<void> build() async {
    if (kIsWeb) return;

    _notificationService = FirebaseNotificationService.instance;

    try {
      final granted = await _notificationService.requestPermission();
      if (granted) {
        await _notificationService.setupListeners(
          onTokenRefreshed: (token) {
            _syncFcmToken(
              token: token,
              userId: ref.read(loggedInUserIdProvider),
            );
          },
          onOpened: _handleNotificationNavigation,
          onNotificationTapped: _handleNotificationTap,
        );
      }
    } catch (error) {
      Logger.logError("[FcmNotificationInit] => $error");
    }
  }

  void _syncFcmToken({required String token, required int? userId}) {
    final storageService = ref.read(storageServiceProvider);
    final lastSyncedFcmToken = storageService.get(
      StorageKeys.lastSyncedFcmToken,
      defaultValue: '',
    );
    final lastSyncedUserId = _parseUserId(
      storageService.get(StorageKeys.lastSyncedFcmUserId),
    );

    if (userId != null &&
        lastSyncedUserId == userId &&
        lastSyncedFcmToken == token) {
      return;
    }

    ref
        .read(fcmDeviceAddOrUpdateRequestStateProvider.notifier)
        .registerOrUpdateFcmDevice(
          token: token,
          onSuccess: () {
            if (!ref.mounted) return;
            storageService.set(StorageKeys.lastSyncedFcmToken, token);
            if (userId != null) {
              storageService.set(StorageKeys.lastSyncedFcmUserId, userId);
            }
          },
        );
  }

  int? _parseUserId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    _handleNotificationData(message.data, source: 'remote');
  }

  void _handleNotificationTap(NotificationResponse response) {
    final data = response.data;
    _handleNotificationData(data, source: 'local');
  }

  void _handleNotificationData(
    Map<String, dynamic> data, {
    required String source,
  }) {
    if (data.isEmpty) {
      Logger.logMessage('[FCM] Notification data is empty. Skipping routing.');
      return;
    }
  }
}
