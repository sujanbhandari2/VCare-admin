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

  static final RegExp _urlPattern = RegExp(r'https?://', caseSensitive: false);

  static final RegExp _technicalPattern = RegExp(
    r'DioException|SocketException|HandshakeException|FileSystemException|'
    r'status\s*code|HttpException|FormatException|TimeoutException|'
    r'PlatformException|LateInitializationError',
    caseSensitive: false,
  );

  static final RegExp _htmlOrXmlPattern = RegExp(
    r'<!doctype\s+html\b|<html\b|<head\b|<body\b|<title\b|<center\b|'
    r'<h1\b|</\s*html\s*>|<\?xml\b',
    caseSensitive: false,
  );

  static final RegExp _proxyPattern = RegExp(
    r'\b(nginx|cloudflare|bad gateway|gateway timeout|service unavailable|'
    r'internal server error|proxy error|upstream)\b',
    caseSensitive: false,
  );

  static final RegExp _stackTracePattern = RegExp(
    r'#\d+\s+[^\n]+|at\s+[\w.$]+\(|Exception:|Error:',
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

    if (_htmlOrXmlPattern.hasMatch(trimmed) ||
        _proxyPattern.hasMatch(trimmed) ||
        _stackTracePattern.hasMatch(trimmed) ||
        _routePattern.hasMatch(trimmed) ||
        _httpMethodPathPattern.hasMatch(trimmed) ||
        _apiPathPattern.hasMatch(trimmed) ||
        _urlPattern.hasMatch(trimmed) ||
        _technicalPattern.hasMatch(trimmed)) {
      return true;
    }

    // Multi-line payloads and long raw dumps are almost never user-safe copy.
    if (trimmed.contains('\n') && trimmed.length > 120) {
      return true;
    }

    if (trimmed.length > 280) {
      return true;
    }

    return false;
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
  static String sanitize({String? message, HttpErrorType? errorType}) {
    if (!shouldUseGenericNetworkMessage(
      message: message,
      errorType: errorType,
    )) {
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
    if (!shouldUseGenericNetworkMessage(
      message: message,
      errorType: errorType,
    )) {
      return message!.trim();
    }

    final l10n = context.appLocalization;

    return switch (errorType) {
      HttpErrorType.timeout => l10n.connectionTimeoutError,
      HttpErrorType.noInternet => l10n.no_internet_connection,
      HttpErrorType.forbidden => l10n.connectionError,
      HttpErrorType.unauthorized => l10n.connectionError,
      _ => l10n.connectionError,
    };
  }

  static String _fallbackForErrorType(HttpErrorType? errorType) {
    return switch (errorType) {
      HttpErrorType.timeout => 'Connection timeout',
      HttpErrorType.noInternet => 'No active internet connection',
      HttpErrorType.forbidden =>
        'You do not have permission to perform this action.',
      HttpErrorType.unauthorized =>
        'Authentication is required for this request.',
      HttpErrorType.notFound => 'Requested resource was not found.',
      HttpErrorType.cancelled => 'Request was cancelled.',
      HttpErrorType.badCertificate => 'Could not verify server certificate.',
      HttpErrorType.tooManyRequests => 'Too many requests. Please retry later.',
      HttpErrorType.server =>
        'Server encountered an error. Please try again later.',
      _ => 'Unable to connect to server. Check your internet connection.',
    };
  }
}

extension HttpExceptionUserMessageX on HttpException {
  String get userMessage =>
      NetworkErrorMessage.sanitize(message: message, errorType: errorType);
}
