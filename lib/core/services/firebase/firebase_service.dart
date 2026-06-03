import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../firebase_options.dart';
import '../../../shared/utils/logger.dart';
import 'firebase_notification_service.dart';
import 'firebase_remote_config_service.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Setup and initialize location notification
      if (!kIsWeb) {
        await FirebaseRemoteConfigService.instance.init();
        await FirebaseNotificationService.instance.initialize();
      }
    } catch (e) {
      Logger.logError("[main -> initializeApp] ---> $e");
    }
  }
}
