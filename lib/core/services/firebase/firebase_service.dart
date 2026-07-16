import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../../shared/utils/logger.dart';
import 'firebase_notification_service.dart';
import 'firebase_remote_config_service.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    await _ensureFirebaseApp();

    if (kIsWeb) return;

    try {
      await FirebaseRemoteConfigService.instance.init();
    } catch (e) {
      Logger.logError('[Firebase] Remote config init failed: $e');
    }

    try {
      await FirebaseNotificationService.instance.initialize();
    } catch (e) {
      Logger.logError('[Firebase] Notification service init failed: $e');
    }
  }

  /// Ensures the default Firebase app exists.
  ///
  /// On hot restart the Dart isolate resets while the native Firebase app
  /// may still be registered, which surfaces as [FirebaseException] with code
  /// `duplicate-app`. That case is safe to ignore.
  static Future<void> _ensureFirebaseApp() async {
    if (Firebase.apps.isNotEmpty) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        Logger.logMessage(
          '[Firebase] Default app already exists (expected on hot restart)',
        );
        return;
      }
      Logger.logError('[main -> initializeApp] ---> $e');
    } catch (e) {
      Logger.logError('[main -> initializeApp] ---> $e');
    }
  }
}
