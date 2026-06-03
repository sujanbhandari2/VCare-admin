import 'dart:async';
import 'package:in_app_update/in_app_update.dart';
import 'package:flutter_template/shared/utils/logger.dart';

class AndroidInAppUpdater {
  /// Method to check for updates and start flexible or force update
  /// [force] - If force is true then immediate update will be performed
  ///
  static Future<void> check4Update([bool force = false]) async {
    try {
      // Check if update is available or not
      final available = await _isUpdateAvailable();

      // If not available, return from here
      if (!available) return;

      // else start update
      // If force is true
      if (force) {
        await performImmediateUpdate();
        return;
      }

      // Else perform flexible update
      final success = await performFlexibleUpdate();

      // If failed
      if (!success) return;

      // Else if flexible update downloaded successfully then complete installation
      await completeFlexibleUpdate();
    } catch (e) {
      Logger.logError("[AndroidInAppUpdate.check4Update] - $e");
    }
  }

  /// Method to check if update is available
  ///
  static Future<bool> _isUpdateAvailable() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      return info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (e) {
      Logger.logError("[AndroidInAppUpdate.isUpdateAvailable] - $e");
      return false;
    }
  }

  /// Method to perform immediate update
  ///
  static Future<bool> performImmediateUpdate() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      Logger.logError("[AndroidInAppUpdate.performImmediateUpdate] - $e");
      return false;
    }
  }

  /// Method to perform flexible update
  ///
  static Future<bool> performFlexibleUpdate() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      return result == AppUpdateResult.success;
    } catch (e) {
      Logger.logError("[AndroidInAppUpdate.performFlexibleUpdate] - $e");
      return false;
    }
  }

  /// Method to complete flexible update
  ///
  static Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      Logger.logError("[AndroidInAppUpdate.completeFlexibleUpdate] - $e");
    }
  }
}
