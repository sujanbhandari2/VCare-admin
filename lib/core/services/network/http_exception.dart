import 'package:dio/dio.dart';

import '../../../shared/utils/extension_functions.dart';

enum HttpErrorType {
  cancelled,
  timeout,
  noInternet,
  badCertificate,
  unauthorized,
  forbidden,
  notFound,
  tooManyRequests,
  server,
  client,
  unknown,
}

/// Custom exception used with HTTP requests.
///
class HttpException implements Exception {
  /// Creates a new instance of [HttpException].
  ///
  /// [title] - The title of the exception (optional).
  /// [message] - A detailed message about the exception (optional).
  /// [statusCode] - The HTTP response status code associated with the exception (optional).
  /// [dioException] - The DioException that caused the error (optional).
  ///
  HttpException({
    this.title,
    this.message,
    this.statusCode,
    this.dioException,
    this.errorType = HttpErrorType.unknown,
    this.requestMethod,
    this.requestUri,
    this.responseData,
  });

  /// The title of the exception, providing a brief description.
  ///
  final String? title;

  /// The detailed message associated with the exception.
  ///
  final String? message;

  /// The HTTP status code returned by the server (if available).
  ///
  final int? statusCode;

  /// The DioException that caused the error (if available).
  ///
  final DioException? dioException;

  /// Error type used to categorize network failures.
  final HttpErrorType errorType;

  /// Request method that caused this exception.
  final String? requestMethod;

  /// Request URI that caused this exception.
  final Uri? requestUri;

  /// Response body payload (if available).
  final dynamic responseData;

  /// Whether the error is generally safe to retry automatically.
  bool get isRetryable => switch (errorType) {
    HttpErrorType.timeout ||
    HttpErrorType.noInternet ||
    HttpErrorType.tooManyRequests ||
    HttpErrorType.server => true,
    _ => false,
  };

  /// Creates an [HttpException] from an HTTP [Response].
  ///
  /// [response] - The response object returned by Dio.
  /// Attempts to extract a message from the response data or falls back to the status message.
  ///
  static HttpException fromResponse(Response<dynamic> response) {
    final requestOptions = response.requestOptions;
    final resolvedType = _mapStatusCodeToErrorType(response.statusCode);

    return HttpException(
      title: _titleForErrorType(resolvedType),
      statusCode: response.statusCode,
      message:
          extractMessageFromResponse(response) ??
          response.statusMessage ??
          _defaultMessageForErrorType(resolvedType),
      errorType: resolvedType,
      requestMethod: requestOptions.method,
      requestUri: requestOptions.uri,
      responseData: response.data,
    );
  }

  /// Creates an [HttpException] from a Dio [Exception].
  ///
  /// [error] - The error object thrown by Dio, typically a [DioException].
  /// If the error is a DioException, it is captured; otherwise, a generic exception message is provided.
  ///
  static HttpException fromException(dynamic error) {
    if (error is HttpException) {
      return error;
    }

    if (error is DioException) {
      return fromDioException(error);
    }

    return HttpException(
      statusCode: 500,
      title: 'Unexpected Error',
      message: error?.toString() ?? 'Unable to handle your request',
      errorType: HttpErrorType.unknown,
    );
  }

  /// Creates an [HttpException] from a [DioException].
  static HttpException fromDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final resolvedType = _mapDioErrorType(error, statusCode);

    return HttpException(
      title: _titleForErrorType(resolvedType),
      statusCode: statusCode ?? _statusCodeForErrorType(resolvedType),
      message:
          (response != null ? extractMessageFromResponse(response) : null) ??
          error.message ??
          _defaultMessageForErrorType(resolvedType),
      dioException: error,
      errorType: resolvedType,
      requestMethod: error.requestOptions.method,
      requestUri: error.requestOptions.uri,
      responseData: response?.data,
    );
  }

  /// Tries to extract an API message from a [response] payload.
  ///
  static String? extractMessageFromResponse(Response<dynamic> response) {
    return _extractMessage(response.data);
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final message = data.trim();
      if (message.isEmpty) return null;
      // Reject HTML/proxy pages so they never become the primary exception message.
      if (_looksLikeNonUserMessage(message)) return null;
      return message;
    }

    if (data is Map<String, dynamic>) {
      if (data['errors'] is List) {
        final errors = data['errors'] as List<dynamic>;
        for (final error in errors) {
          final extracted = _extractMessage(error);
          if (extracted != null) return extracted;
        }
      }

      if (data['messages'] is List) {
        final errors = data['messages'] as List<dynamic>;
        for (final error in errors) {
          final extracted = _extractMessage(error);
          if (extracted != null) return extracted;
        }
      }

      const messageFields = [
        'message',
        'Message',
        'details',
        'detail',
        'error',
      ];

      for (final key in messageFields) {
        final extracted = _extractMessage(data[key]);
        final fields = data['path'];
        final field = fields is List ? fields.join('.') : fields?.toString();
        if (extracted != null) {
          return field == null
              ? extracted
              : '${field.capitalize} ${extracted.toLowerCase()}';
        }
      }
    }

    if (data is List) {
      for (final item in data) {
        final extracted = _extractMessage(item);
        if (extracted != null) return extracted;
      }
    }

    return null;
  }

  static final RegExp _nonUserMessagePattern = RegExp(
    r'<!doctype\s+html\b|<html\b|<head\b|<body\b|<title\b|</\s*html\s*>|'
    r'<\?xml\b|\bnginx\b|\bcloudflare\b',
    caseSensitive: false,
  );

  static bool _looksLikeNonUserMessage(String message) {
    final trimmed = message.trim();
    if (_nonUserMessagePattern.hasMatch(trimmed)) return true;
    if (trimmed.contains('\n') && trimmed.length > 120) return true;
    return false;
  }

  @override
  String toString() {
    return 'HttpException{title: $title, message: $message, statusCode: $statusCode, errorType: $errorType, requestMethod: $requestMethod, requestUri: $requestUri, dioException: $dioException}';
  }

  static HttpErrorType _mapDioErrorType(DioException error, int? statusCode) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return HttpErrorType.timeout;
      case DioExceptionType.connectionError:
        return HttpErrorType.noInternet;
      case DioExceptionType.badCertificate:
        return HttpErrorType.badCertificate;
      case DioExceptionType.cancel:
        return HttpErrorType.cancelled;
      case DioExceptionType.badResponse:
        return _mapStatusCodeToErrorType(statusCode);
      case DioExceptionType.unknown:
        return _mapStatusCodeToErrorType(statusCode);
    }
  }

  static HttpErrorType _mapStatusCodeToErrorType(int? statusCode) {
    if (statusCode == null) return HttpErrorType.unknown;
    if (statusCode == 401) return HttpErrorType.unauthorized;
    if (statusCode == 403) return HttpErrorType.forbidden;
    if (statusCode == 404) return HttpErrorType.notFound;
    if (statusCode == 429) return HttpErrorType.tooManyRequests;
    if (statusCode >= 500) return HttpErrorType.server;
    if (statusCode >= 400) return HttpErrorType.client;
    return HttpErrorType.unknown;
  }

  static int _statusCodeForErrorType(HttpErrorType errorType) {
    switch (errorType) {
      case HttpErrorType.timeout:
        return 408;
      case HttpErrorType.noInternet:
        return 503;
      case HttpErrorType.cancelled:
        return 499;
      case HttpErrorType.badCertificate:
        return 495;
      default:
        return 500;
    }
  }

  static String _titleForErrorType(HttpErrorType errorType) {
    switch (errorType) {
      case HttpErrorType.timeout:
        return 'Request Timeout';
      case HttpErrorType.noInternet:
        return 'Network Error';
      case HttpErrorType.cancelled:
        return 'Request Cancelled';
      case HttpErrorType.badCertificate:
        return 'Certificate Error';
      case HttpErrorType.unauthorized:
        return 'Unauthorized';
      case HttpErrorType.forbidden:
        return 'Access Denied';
      case HttpErrorType.notFound:
        return 'Not Found';
      case HttpErrorType.tooManyRequests:
        return 'Rate Limited';
      case HttpErrorType.server:
        return 'Server Error';
      case HttpErrorType.client:
        return 'Request Error';
      case HttpErrorType.unknown:
        return 'HTTP Error';
    }
  }

  static String _defaultMessageForErrorType(HttpErrorType errorType) {
    switch (errorType) {
      case HttpErrorType.timeout:
        return 'Request timed out. Please try again.';
      case HttpErrorType.noInternet:
        return 'No internet connection. Please check your network.';
      case HttpErrorType.cancelled:
        return 'Request was cancelled.';
      case HttpErrorType.badCertificate:
        return 'Could not verify server certificate.';
      case HttpErrorType.unauthorized:
        return 'Authentication is required for this request.';
      case HttpErrorType.forbidden:
        return 'You do not have permission to perform this action.';
      case HttpErrorType.notFound:
        return 'Requested resource was not found.';
      case HttpErrorType.tooManyRequests:
        return 'Too many requests. Please retry later.';
      case HttpErrorType.server:
        return 'Server encountered an error. Please try again later.';
      case HttpErrorType.client:
        return 'Request failed due to invalid input or state.';
      case HttpErrorType.unknown:
        return 'Unable to handle your request.';
    }
  }
}
