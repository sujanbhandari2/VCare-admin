import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/shared/session/user_session_cleanup.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Global handler for API auth-session failures that require forced logout.
class SessionExpiryHandler {
  SessionExpiryHandler({
    required this.storageService,
    required this.apiBaseUrl,
  });

  final StorageService storageService;
  final String apiBaseUrl;

  /// Prevents duplicate toast/logout when multiple requests fail at once.
  static bool _isHandling = false;
  static String? _pendingToastMessage;

  static const String sessionNotFoundMessage = 'session not found';
  static const String invalidTokenMessage = 'invalid token';

  static const String sessionExpiredToast =
      'Your session has been expired. Please sign in again.';
  static const String invalidTokenToast = 'Invalid token. Please sign in again.';

  /// Returns a normalized expiry message when [message] matches a known
  /// force-logout API message; otherwise null.
  static String? normalizedExpiredMessage(dynamic message) {
    if (message == null) return null;
    final normalized = message.toString().trim().toLowerCase();
    if (normalized.contains(invalidTokenMessage)) {
      return invalidTokenMessage;
    }
    if (normalized.contains(sessionNotFoundMessage)) {
      return sessionNotFoundMessage;
    }
    return null;
  }

  /// Returns a normalized expiry message from a failed API envelope body.
  static String? expiredMessageFromBody(dynamic data) {
    if (data is! Map) return null;
    final success = data['success'];
    if (success is bool && success) return null;
    return normalizedExpiredMessage(data['message']);
  }

  static String toastForNormalizedMessage(String normalizedMessage) {
    // Prefer invalid-token copy whenever that is the API failure.
    if (normalizedMessage.contains(invalidTokenMessage)) {
      return invalidTokenToast;
    }
    return sessionExpiredToast;
  }

  /// Shows toast based on the original API message, clears session, navigates.
  Future<void> handleFromApiMessage(dynamic apiMessage) async {
    final normalized = normalizedExpiredMessage(apiMessage);
    if (normalized == null) return;
    await handle(toastMessage: toastForNormalizedMessage(normalized));
  }

  /// Shows toast, clears session, and navigates to login.
  Future<void> handle({required String toastMessage}) async {
    if (_isHandling) {
      // If an Invalid token arrives while a generic session toast is pending,
      // upgrade the visible message to Invalid token.
      if (toastMessage == invalidTokenToast &&
          _pendingToastMessage == sessionExpiredToast) {
        _pendingToastMessage = invalidTokenToast;
        _showToast(invalidTokenToast);
      }
      return;
    }
    _isHandling = true;
    _pendingToastMessage = toastMessage;

    try {
      _showToast(_pendingToastMessage ?? toastMessage);
      await clearSession();
    } finally {
      _pendingToastMessage = null;
      Future<void>.delayed(const Duration(seconds: 3), () {
        _isHandling = false;
      });
    }
  }

  void _showToast(String toastMessage) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    try {
      context?.showVcareToast(
        title: toastMessage,
        variant: VcareToastVariant.destructive,
        duration: const Duration(seconds: 3),
      );
    } catch (_) {}
  }

  /// Convenience: handle when a body/message indicates session expiry.
  Future<void> handleIfExpired({
    dynamic body,
    dynamic message,
  }) async {
    final expired =
        expiredMessageFromBody(body) ?? normalizedExpiredMessage(message);
    if (expired == null) return;
    await handle(toastMessage: toastForNormalizedMessage(expired));
  }

  Future<void> clearSession() async {
    ProviderContainer? container;
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null) {
      try {
        container = ProviderScope.containerOf(context);
      } catch (_) {}
    }

    await clearUserSessionWithoutRef(
      storage: storageService,
      apiBaseUrl: apiBaseUrl,
      container: container,
    );

    try {
      AppRouter.rootNavigatorKey.currentContext?.goNamed(
        AppRouter.login.toPathName,
      );
    } catch (_) {}
  }
}
