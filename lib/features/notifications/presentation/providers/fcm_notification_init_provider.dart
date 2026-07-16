import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vcare_admin/core/services/firebase/firebase_notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/storage/storage_keys.dart';
import '../../../../core/services/storage/storage_service_provider.dart';
import '../../../../shared/utils/logger.dart';
import '../../../auth/presentation/providers/logged_in_user_id_provider.dart';
import 'notification_repository_provider.dart';

part 'fcm_notification_init_provider.g.dart';

@Riverpod(keepAlive: true)
class FcmNotificationInitNotifier extends _$FcmNotificationInitNotifier {
  late FirebaseNotificationService _notificationService;

  @override
  Future<void> build() async {
    if (kIsWeb) return;

    _notificationService = FirebaseNotificationService.instance;
    await _notificationService.initialize();

    ref.listen<int?>(loggedInUserIdProvider, (previous, next) {
      if (next != null && next != previous) {
        // TODO: Re-enable when FCM device APIs are available.
        // syncFcmTokenNow(userId: next);
      }
    });

    try {
      await _notificationService.setupOpenAppListeners(
        onOpened: _handleNotificationNavigation,
        onNotificationTapped: _handleNotificationTap,
      );

      final granted = await _notificationService.requestPermission();
      if (!granted) {
        Logger.logWarning('[FCM] Notification permission not granted');
        return;
      }

      await _notificationService.setupTokenAndMessageListeners(
        onTokenRefreshed: (token) {
          // TODO: Re-enable when FCM device APIs are available.
          // _syncFcmToken(
          //   token: token,
          //   userId: ref.read(loggedInUserIdProvider),
          // );
        },
      );

      // final userId = ref.read(loggedInUserIdProvider);
      // if (userId != null) {
      //   await syncFcmTokenNow(userId: userId);
      // }
    } catch (error) {
      Logger.logError("[FcmNotificationInit] => $error");
    }
  }

  Future<void> syncFcmTokenNow({required int userId}) async {
    if (kIsWeb) return;

    final token = await _notificationService.getToken();
    if (token == null || token.trim().isEmpty) return;

    await _syncFcmToken(token: token, userId: userId);
  }

  Future<void> _syncFcmToken({
    required String token,
    required int? userId,
  }) async {
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

    // final payloads = <String, dynamic>{
    //   'fcmToken': token.trim(),
    //   'fcmPlatform': Platform.isIOS ? 'IOS' : 'ANDROID',
    // };

    // TODO: Re-enable when FCM device APIs are available.
    // final checkResponse = await ref
    //     .read(notificationRepositoryProvider)
    //     .checkFcmDeviceStatus();
    //
    // await checkResponse.when(
    //   failure: (_) async {
    //     await _registerOrUpdateToken(
    //       token: token,
    //       userId: userId,
    //       useUpdate: false,
    //       payloads: payloads,
    //     );
    //   },
    //   success: (status) async {
    //     final shouldUpdate = status.hasFcmToken &&
    //         status.fcmRegistrationToken != null &&
    //         status.fcmRegistrationToken != token;
    //
    //     await _registerOrUpdateToken(
    //       token: token,
    //       userId: userId,
    //       useUpdate: status.hasFcmToken || shouldUpdate,
    //       payloads: payloads,
    //     );
    //   },
    // );
  }

  Future<void> _registerOrUpdateToken({
    required String token,
    required int? userId,
    required bool useUpdate,
    required Map<String, dynamic> payloads,
  }) async {
    final repository = ref.read(notificationRepositoryProvider);
    final response = useUpdate
        ? await repository.updateDeviceToken(payloads: payloads)
        : await repository.registerDeviceToken(payloads: payloads);

    response.when(
      failure: (error) {
        Logger.logError('[FCM] Token sync failed: ${error.message}');
      },
      success: (_) {
        if (!ref.mounted) return;
        final storageService = ref.read(storageServiceProvider);
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
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _handleNotificationData(const {}, source: 'local');
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationData(decoded, source: 'local');
        return;
      }
      if (decoded is Map) {
        _handleNotificationData(
          Map<String, dynamic>.from(decoded),
          source: 'local',
        );
        return;
      }
    } catch (_) {}

    _handleNotificationData(const {}, source: 'local');
  }

  void _handleNotificationData(
    Map<String, dynamic> data, {
    required String source,
  }) {
    if (data.isEmpty) {
      Logger.logMessage('[FCM] Notification data is empty. Skipping routing.');
      return;
    }

    Logger.logMessage('[FCM] Notification data received from $source: $data');
  }
}
