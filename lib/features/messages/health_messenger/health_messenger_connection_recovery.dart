import 'package:flutter/widgets.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

/// Decides how to restore Health Messenger when the package drops while
/// the device still has a network path.
///
/// Socket.io and [PresenceController] own the first reconnect. The host only
/// bootstraps a missing session or force-resets a socket that stayed down.
enum HealthMessengerRecoveryAction {
  none,
  bootstrapSession,
  reconnectSocket,
  restartSession,
}

abstract final class HealthMessengerConnectionRecovery {
  /// Backup poll for a missing session or a missed connection event.
  static const Duration watchdogInterval = Duration(seconds: 15);

  /// Wait for native socket.io / presence reconnect before a force reset.
  static const Duration nativeReconnectGrace = Duration(seconds: 4);

  /// Let connectivity settle before treating the path as restored.
  static const Duration connectivitySettle = Duration(milliseconds: 600);

  static const int restartSessionAfterFailures = 3;

  static bool isForegroundLifecycle(AppLifecycleState? lifecycleState) {
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  static bool isSocketInProgress(ChatConnectionState connectionState) {
    return connectionState == ChatConnectionState.connecting ||
        connectionState == ChatConnectionState.reconnecting;
  }

  static bool isSocketHealthy(ChatConnectionState connectionState) {
    return connectionState == ChatConnectionState.connected;
  }

  static bool isSocketDown(ChatConnectionState connectionState) {
    return connectionState == ChatConnectionState.disconnected ||
        connectionState == ChatConnectionState.failed;
  }

  /// Rising edge only. The first observation (`previousUsable == null`) is not
  /// a restore — the watchdog covers that case.
  static bool isNetworkRestored({
    required bool? previousUsable,
    required bool currentUsable,
  }) {
    return previousUsable == false && currentUsable;
  }

  static bool shouldAttempt({
    required bool hasInternet,
    required bool isForeground,
    required bool recoverInFlight,
    required bool isBootstrapping,
  }) {
    return hasInternet && isForeground && !recoverInFlight && !isBootstrapping;
  }

  static HealthMessengerRecoveryAction action({
    required bool sessionReady,
    required ChatConnectionState connectionState,
    required int consecutiveSocketFailures,
    Duration disconnectedFor = Duration.zero,
    bool bypassNativeGrace = false,
  }) {
    if (!sessionReady) {
      return HealthMessengerRecoveryAction.bootstrapSession;
    }
    if (isSocketHealthy(connectionState) ||
        isSocketInProgress(connectionState)) {
      return HealthMessengerRecoveryAction.none;
    }
    if (!bypassNativeGrace && disconnectedFor < nativeReconnectGrace) {
      return HealthMessengerRecoveryAction.none;
    }
    if (consecutiveSocketFailures >= restartSessionAfterFailures) {
      return HealthMessengerRecoveryAction.restartSession;
    }
    return HealthMessengerRecoveryAction.reconnectSocket;
  }
}
