import 'package:dio/dio.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';

/// Abstraction for HTTP requests with unified payload handling.
abstract class ApiClient {
  String get baseUrl;
  Map<String, String> get headers;

  /// Sends a GET request to the given [endpoint].
  ///
  /// [endpoint] - The URL path to append to [baseUrl] for the request.
  /// [queryParameters] - Optional parameters to include in the URL query string.
  /// [isAuthenticated] - Flag indicating if authentication is required (default is true).
  /// [forceRefresh] - Flag to force the refresh of data (default is false).
  /// [cancelToken] - Token to cancel the request before completion.
  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    bool forceRefresh = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  });

  /// Sends a POST request to the given [endpoint] with [formData].
  ///
  /// [endpoint] - The URL path to append to [baseUrl] for the request.
  /// [formData] - Data to send in the body of the POST request, typically as multipart/form-data.
  /// [queryParameters] - Optional parameters to include in the URL query string.
  /// [contentType] - Specifies the content type of the request (default is [ContentType.formData]).
  /// [isAuthenticated] - Flag indicating if authentication is required (default is false).
  /// [cancelToken] - Token to cancel the request before completion.
  Future<Response<dynamic>> post(
    String endpoint,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  });

  /// Sends a PUT request to the given [endpoint] with [formData].
  ///
  /// [endpoint] - The URL path to append to [baseUrl] for the request.
  /// [formData] - Data to send in the body of the PUT request, typically as multipart/form-data.
  /// [queryParameters] - Optional parameters to include in the URL query string.
  /// [isAuthenticated] - Flag indicating if authentication is required (default is true).
  /// [contentType] - Specifies the content type of the request (default is [ContentType.json]).
  /// [cancelToken] - Token to cancel the request before completion.
  Future<Response<dynamic>> put(
    String endpoint,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  });

  /// Sends a PATCH request to the given [endpoint] with [formData].
  ///
  /// [endpoint] - The URL path to append to [baseUrl] for the request.
  /// [formData] - Data to send in the body of the PATCH request, typically as multipart/form-data.
  /// [queryParameters] - Optional parameters to include in the URL query string.
  /// [isAuthenticated] - Flag indicating if authentication is required (default is true).
  /// [contentType] - Specifies the content type of the request (default is [ContentType.json]).
  /// [cancelToken] - Token to cancel the request before completion.
  Future<Response<dynamic>> patch(
    String endpoint,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  });

  /// Sends a GET request to download data from the given [endpoint].
  ///
  /// [endpoint] - The URL path to append to [baseUrl] for the request.
  /// [queryParameters] - Optional parameters to include in the URL query string.
  /// [onReceiveProgress] - A callback function to report download progress.
  /// [cancelToken] - Token to cancel the request before completion.
  Future<Response<dynamic>> download(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    void Function(int count, int total)? onReceiveProgress,
    String? customBaseUrl,
    CancelToken? cancelToken,
  });

  /// Sends a DELETE request to the given [endpoint] with optional [formData].
  ///
  /// [endpoint] - The URL path to append to [baseUrl] for the request.
  /// [formData] - Optional data to send in the body of the DELETE request.
  /// [queryParameters] - Optional parameters to include in the URL query string.
  /// [isAuthenticated] - Flag indicating if authentication is required (default is false).
  /// [contentType] - Specifies the content type of the request (default is [ContentType.json]).
  /// [cancelToken] - Token to cancel the request before completion.
  Future<Response<dynamic>> delete(
    String endpoint, {
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  });
}
