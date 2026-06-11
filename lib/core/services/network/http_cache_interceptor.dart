import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:vcare_admin/shared/utils/logger.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/core/services/network/models/cache_response.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';

/// Dio Interceptor used to cache HTTP responses in local storage
class CacheInterceptor extends Interceptor {
  /// Creates new instance of [CacheInterceptor]
  CacheInterceptor(this.config, this.storageService);

  /// Flavor Configuration
  final Configuration config;

  /// Storage service used to store cache in local storage
  final StorageService storageService;

  /// Key used to control cache force refresh in request options
  String get _forceRefreshKey => config.dioCacheForceRefreshKey;

  /// Method that intercepts Dio error
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Logger.logRaw("""
    ❌ Dio Error! ❌
    ❌ Url: ${err.requestOptions.uri}
    ❌ Response Errors: ${err.response?.data}
    """);

    // For 4xx/5xx errors, we want to pass through the error response
    if (err.response?.statusCode != null && err.response!.statusCode! >= 400) {
      return handler.resolve(
        err.response ?? Response(requestOptions: err.requestOptions),
      );
    }

    if (_tryResolveFromCache(err.requestOptions, null, handler)) return;

    handler.next(err);
  }

  /// Method that intercepts Dio request
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_shouldForceRefresh(options)) {
      if (_isGetRequest(options)) {
        Logger.logRaw('🌍 Retrieving request from network (force refresh)');
      }
      return handler.next(options);
    }

    if (_tryResolveFromCache(options, handler, null)) return;

    handler.next(options);
  }

  /// Method that intercepts Dio response
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Only cache successful responses
    if (_isResponseSuccessful(response)) {
      _logResponse(response, 'network');
      _cacheIt(response);
    }

    handler.next(response);
  }

  /// Determines if a request should be forced to refresh
  ///
  bool _shouldForceRefresh(RequestOptions options) {
    return !_isGetRequest(options) ||
        !options.extra.containsKey(_forceRefreshKey) ||
        options.extra[_forceRefreshKey] == true;
  }

  /// Determines if a response is successful
  ///
  bool _isResponseSuccessful(Response<dynamic> response) {
    final bool isStatusOk =
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;

    if (!isStatusOk) return false;

    // Check for application-level success flag
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('success')) {
        return data['success'] == true;
      }
    }

    return true;
  }

  /// Method to store response in cache
  ///
  Future<void> _cacheIt(Response<dynamic> response) async {
    final storageKey = createStorageKey(
      response.requestOptions.method,
      response.requestOptions.baseUrl,
      response.requestOptions.path,
      response.requestOptions.queryParameters,
    );

    final cachedResponse = CachedResponse(
      data: response.data,
      headers: Headers.fromMap(response.headers.map),
      age: clock.now(),
      statusCode: response.statusCode ?? 0,
    );

    storageService.set(storageKey, cachedResponse.toJson());
    Logger.logRaw('🏗 Saved response to cache');
  }

  /// Get cached response by storage key with error handling
  ///
  CachedResponse? _fromCache(String storageKey) {
    try {
      final dynamic rawCachedResponse = storageService.get(storageKey);
      if (rawCachedResponse == null) return null;

      final cachedResponse = CachedResponse.fromJson(
        json.decode(json.encode(rawCachedResponse)) as Map<String, dynamic>,
      );

      if (cachedResponse.isValid) return cachedResponse;

      storageService.remove(storageKey);
      return null;
    } catch (e) {
      storageService.remove(storageKey);
      return null;
    }
  }

  /// Attempt to resolve from cache
  ///
  bool _tryResolveFromCache(
    RequestOptions options,
    RequestInterceptorHandler? requestHandler,
    ErrorInterceptorHandler? errorHandler,
  ) {
    if (!_isGetRequest(options)) return false;

    final storageKey = createStorageKey(
      options.method,
      options.baseUrl,
      options.path,
      options.queryParameters,
    );

    if (!storageService.has(storageKey)) return false;

    final cachedResponse = _fromCache(storageKey);

    if (cachedResponse == null) return false;

    final response = cachedResponse.buildResponse(options);

    _logResponse(response, 'cache');

    if (requestHandler != null) {
      requestHandler.resolve(response);
      return true;
    } else if (errorHandler != null) {
      errorHandler.resolve(response);
      return true;
    }

    return false;
  }

  /// Helper method to create a storage key from request/response information
  ///
  /// e.g. for a GET request to /person/popular endpoint:
  /// storage key: 'GET:https://api.themoviedb.org/3/person/popular/'
  @visibleForTesting
  String createStorageKey(
    String method,
    String baseUrl,
    String path, [
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  ]) {
    final normalizedPath = path.endsWith('/') ? path : '$path/';
    final buffer = StringBuffer(
      '${method.toUpperCase()}:$baseUrl$normalizedPath',
    );

    if (queryParameters.isNotEmpty) {
      buffer.write('?${_canonicalQueryString(queryParameters)}');
    }
    return buffer.toString();
  }

  String _canonicalQueryString(Map<String, dynamic> queryParameters) {
    final sortedKeys = queryParameters.keys.map((k) => k.toString()).toList()
      ..sort();

    final parts = <String>[];
    for (final key in sortedKeys) {
      final value = queryParameters[key];
      parts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(_canonicalValue(value))}',
      );
    }
    return parts.join('&');
  }

  String _canonicalValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) {
      final sorted = value.map(
        (k, v) => MapEntry(k.toString(), _canonicalValue(v)),
      );
      final keys = sorted.keys.toList()..sort();
      final entries = keys.map((k) => '$k:${sorted[k]}').join(',');
      return '{$entries}';
    }
    if (value is List) {
      return '[${value.map(_canonicalValue).join(',')}]';
    }
    return value.toString();
  }

  /// Log response details
  ///
  void _logResponse(Response response, String source) {
    final statusCode = response.statusCode ?? 0;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final url =
        '${response.requestOptions.baseUrl}${response.requestOptions.path}';

    Logger.logRaw("""
      [${source.toUpperCase()}] Retrieved response ${isSuccess ? '✅' : '❌'}
      [$statusCode] $url
      [Query] ${response.requestOptions.queryParameters}
      """);
  }

  /// Method to check if request is get
  ///
  bool _isGetRequest(RequestOptions options) =>
      options.method.toLowerCase() == 'get';
}
