import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vcare_admin/shared/utils/logger.dart';

/// Callback type definitions for notification events
typedef OnTokenRefreshed = void Function(String token);
typedef OnMessageReceived = void Function(RemoteMessage message);
typedef OnMessageOpenedApp = void Function(RemoteMessage message);
typedef OnNotificationTapped = void Function(NotificationResponse response);

OnNotificationTapped? _onNotificationTapped;

/// Configuration class for notification settings
class NotificationServiceConfig {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String androidSmallIcon;
  final int maxRetriesForApnsToken;
  final Duration retryDelayForApnsToken;

  const NotificationServiceConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.androidSmallIcon,
    this.maxRetriesForApnsToken = 5,
    this.retryDelayForApnsToken = const Duration(seconds: 2),
  });

  static const NotificationServiceConfig defaultConfig =
      NotificationServiceConfig(
        channelId: 'vcare_admin_default',
        channelName: 'VCare Notifications',
        channelDescription: 'Notifications for VCare Admin app',
        androidSmallIcon: '@drawable/notification_icon',
        maxRetriesForApnsToken: 5,
        retryDelayForApnsToken: Duration(seconds: 2),
      );
}

class FirebaseNotificationService {
  FirebaseNotificationService._();

  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._();

  static FirebaseNotificationService get instance => _instance;

  late FirebaseMessaging _messaging;
  late FlutterLocalNotificationsPlugin _localNotifications;
  late NotificationServiceConfig _config;

  AndroidNotificationChannel? _channel;

  bool _initialized = false;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openAppSub;

  Future<void> initialize({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    NotificationServiceConfig config = NotificationServiceConfig.defaultConfig,
  }) async {
    if (_initialized) return;

    _messaging = messaging ?? FirebaseMessaging.instance;
    _localNotifications =
        localNotifications ?? FlutterLocalNotificationsPlugin();
    _config = config;

    await _setupLocalNotifications();

    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'FirebaseNotificationService not initialized. Call initialize() first.',
      );
    }
  }

  Future<void> _setupLocalNotifications() async {
    try {
      _channel = AndroidNotificationChannel(
        _config.channelId,
        _config.channelName,
        description: _config.channelDescription,
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel!);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _localNotifications.initialize(
        settings: InitializationSettings(
          android: AndroidInitializationSettings(_config.androidSmallIcon),
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _handleBackgroundNotificationResponse,
      );
    } catch (e, stack) {
      debugPrint('Notification setup failed: $e\n$stack');
      rethrow;
    }
  }

  Future<bool> requestPermission() async {
    _ensureInitialized();

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Permission request failed: $e');
      return false;
    }
  }

  Future<String?> getToken() async {
    _ensureInitialized();

    try {
      if (Platform.isIOS) {
        final apns = await _waitForApnsToken();
        if (apns == null) return null;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        Logger.logMessage('[FCM] Token: $token');
      } else {
        Logger.logWarning('[FCM] Token is null');
      }
      return token;
    } catch (e) {
      Logger.logError('[FCM] Get token failed: $e');
      return null;
    }
  }

  Future<String?> _waitForApnsToken() async {
    for (int i = 0; i < _config.maxRetriesForApnsToken; i++) {
      final token = await _messaging.getAPNSToken();
      if (token != null) return token;

      await Future.delayed(_config.retryDelayForApnsToken);
    }
    return null;
  }

  Future<void> setupOpenAppListeners({
    OnMessageOpenedApp? onOpened,
    OnNotificationTapped? onNotificationTapped,
  }) async {
    _ensureInitialized();

    await _openAppSub?.cancel();
    _openAppSub = FirebaseMessaging.onMessageOpenedApp.listen(onOpened);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onOpened?.call(initialMessage);
    }

    _onNotificationTapped = onNotificationTapped;
  }

  Future<void> setupTokenAndMessageListeners({
    OnTokenRefreshed? onTokenRefreshed,
    OnMessageReceived? onMessage,
  }) async {
    _ensureInitialized();

    await _tokenSub?.cancel();
    await _messageSub?.cancel();

    final token = await getToken();
    if (token != null) {
      onTokenRefreshed?.call(token);
    }

    _tokenSub = _messaging.onTokenRefresh.listen((token) {
      Logger.logMessage('[FCM] Token refreshed: $token');
      onTokenRefreshed?.call(token);
    });

    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message);
      onMessage?.call(message);
    });
  }

  Future<void> setupListeners({
    OnTokenRefreshed? onTokenRefreshed,
    OnMessageReceived? onMessage,
    OnMessageOpenedApp? onOpened,
    OnNotificationTapped? onNotificationTapped,
  }) async {
    await setupOpenAppListeners(
      onOpened: onOpened,
      onNotificationTapped: onNotificationTapped,
    );
    await setupTokenAndMessageListeners(
      onTokenRefreshed: onTokenRefreshed,
      onMessage: onMessage,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (!kIsWeb && Platform.isAndroid) {
      showNotification(message);
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    _ensureInitialized();

    final notification = message.notification;
    if (notification == null) return;

    try {
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel!.id,
            _channel!.name,
            channelDescription: _channel!.description,
            icon: _config.androidSmallIcon,
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.isEmpty ? null : jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    await _messageSub?.cancel();
    await _openAppSub?.cancel();
  }
}

@pragma('vm:entry-point')
void _handleBackgroundNotificationResponse(NotificationResponse response) {
  _onNotificationTapped?.call(response);
}
