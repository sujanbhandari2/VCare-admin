import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/api_response_interceptor.dart';
import 'package:vcare_admin/core/services/network/http_cache_interceptor.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/refresh_token_interceptor.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';

/// API client implementation using Dio with centralized request/error handling.
class DioApiClient implements ApiClient {
  DioApiClient(
    this.config,
    this.storageService, {
    Dio? dioOverride,
    bool enableCaching = true,
  }) {
    dio = dioOverride ?? Dio(baseOptions);

    // Add interceptor to handle base response structure (success/message/data)
    dio.interceptors.add(ApiResponseInterceptor());

    if (enableCaching) {
      // CacheInterceptor is added after _ApiInterceptor so it receives the full response
      // in its onResponse before it gets unwrapped by _ApiInterceptor.
      dio.interceptors.add(CacheInterceptor(config, storageService));
    }

    dio.interceptors.add(
      RefreshTokenInterceptor(
        config: config,
        storageService: storageService,
        dio: dio,
      ),
    );
  }

  static const Duration _defaultTimeout = Duration(minutes: 2);

  final Configuration config;
  final StorageService storageService;
  late final Dio dio;

  BaseOptions get baseOptions => BaseOptions(
    baseUrl: baseUrl,
    headers: headers,
    connectTimeout: _defaultTimeout,
    receiveTimeout: _defaultTimeout,
    sendTimeout: _defaultTimeout,
    // 4xx/5xx should be returned as responses and validated by repository layer or interceptor.
    validateStatus: (_) => true,
  );

  @override
  String get baseUrl => config.apiBaseUrl;

  @override
  Map<String, String> headers = {
    'accept': 'application/json',
    'content-type': RequestMediaType.json,
  };

  @override
  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool forceRefresh = false,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: HttpMethod.get,
      endpoint: endpoint,
      queryParameters: queryParameters,
      additionalHeaders: additionalHeaders,
      isAuthenticated: isAuthenticated,
      forceRefresh: forceRefresh,
      customBaseUrl: customBaseUrl,
      cancelToken: cancelToken,
    );
  }

  @override
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
  }) {
    return _request(
      method: HttpMethod.post,
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      additionalHeaders: additionalHeaders,
      isAuthenticated: isAuthenticated,
      customBaseUrl: customBaseUrl,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
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
  }) {
    return _request(
      method: HttpMethod.put,
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      additionalHeaders: additionalHeaders,
      isAuthenticated: isAuthenticated,
      customBaseUrl: customBaseUrl,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
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
  }) {
    return _request(
      method: HttpMethod.patch,
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      additionalHeaders: additionalHeaders,
      isAuthenticated: isAuthenticated,
      customBaseUrl: customBaseUrl,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<dynamic>> delete(
    String endpoint, {
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: HttpMethod.delete,
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      additionalHeaders: additionalHeaders,
      isAuthenticated: isAuthenticated,
      customBaseUrl: customBaseUrl,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<dynamic>> download(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    void Function(int count, int total)? onReceiveProgress,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: HttpMethod.get,
      endpoint: endpoint,
      queryParameters: queryParameters,
      additionalHeaders: additionalHeaders,
      customBaseUrl: customBaseUrl,
      cancelToken: cancelToken,
      optionsBuilder: (headers) => Options(
        headers: headers,
        responseType: ResponseType.bytes,
        followRedirects: false,
        receiveTimeout: Duration.zero,
      ),
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<dynamic>> _request({
    required HttpMethod method,
    required String endpoint,
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    bool forceRefresh = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
    Options Function(Map<String, String> headers)? optionsBuilder,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      final requestHeaders = _buildHeaders(
        isAuthenticated: isAuthenticated,
        body: body,
        additionalHeaders: additionalHeaders,
      );

      final options =
          (optionsBuilder ??
                  (headers) => Options(
                    headers: headers,
                    extra: {config.dioCacheForceRefreshKey: forceRefresh},
                  ))
              .call(requestHeaders);

      final resolvedPath = _resolveEndpointPath(endpoint, customBaseUrl);
      final data = await body?.encode();

      return await dio.request<dynamic>(
        resolvedPath,
        data: data,
        queryParameters: queryParameters,
        options: options.copyWith(method: method.name.toUpperCase()),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (error) {
      throw HttpException.fromException(error);
    }
  }

  Map<String, String> _buildHeaders({
    required bool isAuthenticated,
    required RequestBody? body,
    Map<String, String>? additionalHeaders,
  }) {
    final merged = <String, String>{
      ...headers,
      ..._getAuthHeaders(isAuthenticated),
      ...?additionalHeaders,
    };

    final contentType = body?.contentType;

    if (contentType == null || contentType.trim().isEmpty) {
      merged.remove('content-type');
    } else {
      merged['content-type'] = contentType;
    }

    return merged;
  }

  Map<String, String> _getAuthHeaders(bool isAuthenticated) {
    if (!isAuthenticated) return {};

    final token = storageService.get(StorageKeys.loggedInUserToken)?.toString();
    if (token == null || token.trim().isEmpty) return {};

    return {'Authorization': 'Bearer $token'};
  }

  String _resolveEndpointPath(String endpoint, String? customBaseUrl) {
    if (customBaseUrl == null || customBaseUrl.trim().isEmpty) {
      return endpoint;
    }

    final sanitizedBaseUrl = customBaseUrl.endsWith('/')
        ? customBaseUrl.substring(0, customBaseUrl.length - 1)
        : customBaseUrl;
    final sanitizedEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;

    return '$sanitizedBaseUrl/$sanitizedEndpoint';
  }
}

enum HttpMethod { get, post, put, patch, delete }
