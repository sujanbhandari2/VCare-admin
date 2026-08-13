import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../firebase_options.dart';
import 'firebase_notification_service.dart';

/// Top-level background FCM handler. Must be registered before [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || !Platform.isAndroid) return;

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await showBackgroundAndroidNotification(message);
}

/// Lightweight local notification display for the background isolate.
Future<void> showBackgroundAndroidNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final config = NotificationServiceConfig.defaultConfig;
  final localNotifications = FlutterLocalNotificationsPlugin();

  final channel = AndroidNotificationChannel(
    config.channelId,
    config.channelName,
    description: config.channelDescription,
    importance: Importance.max,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await localNotifications.initialize(
    settings: InitializationSettings(
      android: AndroidInitializationSettings(config.androidSmallIcon),
    ),
  );

  try {
    await localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: config.androidSmallIcon,
          largeIcon: const DrawableResourceAndroidBitmap(
            '@mipmap/ic_launcher',
          ),
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  } catch (e) {
    debugPrint('Background notification display failed: $e');
  }
}
