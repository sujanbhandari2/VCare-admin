import 'package:flutter/widgets.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Utilities for converting raw API/network failures into user-safe copy.
class NetworkErrorMessage {
  const NetworkErrorMessage._();

  static final RegExp _routePattern = RegExp(
    r'Route\s+(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s*\S*',
    caseSensitive: false,
  );

  static final RegExp _httpMethodPathPattern = RegExp(
    r'\b(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+[/\w]',
    caseSensitive: false,
  );

  static final RegExp _apiPathPattern = RegExp(
    r'/(api|v\d+)/',
    caseSensitive: false,
  );

  static final RegExp _urlPattern = RegExp(
    r'https?://',
    caseSensitive: false,
  );

  static final RegExp _technicalPattern = RegExp(
    r'DioException|SocketException|HandshakeException|status\s*code|HttpException',
    caseSensitive: false,
  );

  static bool isNetworkRelatedErrorType(HttpErrorType errorType) {
    return switch (errorType) {
      HttpErrorType.timeout ||
      HttpErrorType.noInternet ||
      HttpErrorType.badCertificate ||
      HttpErrorType.server ||
      HttpErrorType.tooManyRequests ||
      HttpErrorType.unknown => true,
      _ => false,
    };
  }

  static bool isTechnicalMessage(String? message) {
    if (message == null) return true;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return true;

    return _routePattern.hasMatch(trimmed) ||
        _httpMethodPathPattern.hasMatch(trimmed) ||
        _apiPathPattern.hasMatch(trimmed) ||
        _urlPattern.hasMatch(trimmed) ||
        _technicalPattern.hasMatch(trimmed);
  }

  static bool shouldUseGenericNetworkMessage({
    String? message,
    HttpErrorType? errorType,
  }) {
    if (errorType != null && isNetworkRelatedErrorType(errorType)) {
      return true;
    }

    return isTechnicalMessage(message);
  }

  /// Returns a safe message for state/notifiers when [BuildContext] is unavailable.
  static String sanitize({
    String? message,
    HttpErrorType? errorType,
  }) {
    if (!shouldUseGenericNetworkMessage(message: message, errorType: errorType)) {
      return message!.trim();
    }

    return _fallbackForErrorType(errorType);
  }

  /// Returns localized copy suitable for UI display.
  static String displayMessage(
    BuildContext context, {
    String? message,
    HttpErrorType? errorType,
  }) {
    if (!shouldUseGenericNetworkMessage(message: message, errorType: errorType)) {
      return message!.trim();
    }

    final l10n = context.appLocalization;

    return switch (errorType) {
      HttpErrorType.timeout => l10n.connectionTimeoutError,
      HttpErrorType.noInternet => l10n.no_internet_connection,
      _ => l10n.connectionError,
    };
  }

  static String _fallbackForErrorType(HttpErrorType? errorType) {
    return switch (errorType) {
      HttpErrorType.timeout => 'Connection timeout',
      HttpErrorType.noInternet => 'No active internet connection',
      _ => 'Unable to connect to server. Check your internet connection.',
    };
  }
}

extension HttpExceptionUserMessageX on HttpException {
  String get userMessage => NetworkErrorMessage.sanitize(
        message: message,
        errorType: errorType,
      );
}
