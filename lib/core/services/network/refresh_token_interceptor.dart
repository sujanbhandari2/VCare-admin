import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/services/network/session_expiry_handler.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/auth/data/auth_device_id.dart';
import 'package:vcare_admin/features/auth/data/repositories/auth_secure_token_store.dart';

/// Interceptor that handles 401 Unauthorized errors by attempting to refresh the JWT token.
/// Also auto-refreshes the token if the last refresh was more than or equal to 2 hours ago.
///
/// Session-expiry logout for "Session not found" / "Invalid token" is primarily handled by
/// [ApiResponseInterceptor] via [SessionExpiryHandler]; this interceptor keeps an error-path
/// backup and clears the session when token refresh fails.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required this.config,
    required this.storageService,
    required this.dio,
    required this.sessionExpiryHandler,
    AuthSecureTokenStore? tokenStore,
  }) : _tokenStore =
            tokenStore ?? AuthSecureTokenStore(storage: storageService);

  final Configuration config;
  final StorageService storageService;
  final Dio dio;
  final SessionExpiryHandler sessionExpiryHandler;
  final AuthSecureTokenStore _tokenStore;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final lastRefreshed = storageService.get(StorageKeys.tokenRefreshedDate);

    if (lastRefreshed != null) {
      final lastRefreshedDate = DateTime.tryParse(lastRefreshed.toString());
      if (lastRefreshedDate != null) {
        final now = DateTime.now();
        final difference = now.difference(lastRefreshedDate);

        if (difference.inHours >= 2) {
          final newToken = await _refreshToken();
          if (newToken != null) {
            options.headers['Authorization'] = 'Bearer $newToken';
          }
        }
      }
    }

    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final apiMessage =
        (err.response?.data is Map
            ? (err.response!.data as Map)['message']
            : null) ??
        err.error;
    if (SessionExpiryHandler.normalizedExpiredMessage(apiMessage) != null) {
      await sessionExpiryHandler.handleFromApiMessage(apiMessage);
      return handler.reject(err);
    }

    if (err.response?.statusCode == 401) {
      final newAccessToken = await _refreshToken();

      if (newAccessToken != null) {
        // Retry the original request
        final requestOptions = err.requestOptions;
        requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        try {
          final retryResponse = await dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          return handler.reject(
            DioException(requestOptions: requestOptions, error: e),
          );
        }
      }
    }
    return super.onError(err, handler);
  }

  /// Attempts to refresh the JWT token.
  /// Returns the new access token if successful, null otherwise.
  Future<String?> _refreshToken() async {
    final refreshToken = storageService
        .get(StorageKeys.loggedInUserRefreshToken)
        ?.toString();

    if (refreshToken == null || refreshToken.isEmpty) {
      await sessionExpiryHandler.clearSession();
      return null;
    }

    try {
      // Use a separate Dio instance to avoid circular dependency/interceptor issues
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: config.apiBaseUrl,
          connectTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final deviceId = await getOrCreateDeviceId(storageService);
      final response = await refreshDio.post(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Device-Id': deviceId,
          },
        ),
      );

      if ([200, 201].contains(response.statusCode)) {
        final data = response.data;

        final tokenData = data['data'];
        final newAccessToken =
            tokenData['accessToken'] ?? tokenData['access_token'];
        final newRefreshToken =
            tokenData['refreshToken'] ?? tokenData['refresh_token'];

        if (newAccessToken == null || newRefreshToken == null) {
          await sessionExpiryHandler.clearSession();
          return null;
        }

        await _tokenStore.save(
          accessToken: newAccessToken.toString(),
          refreshToken: newRefreshToken.toString(),
        );
        await storageService.set(
          StorageKeys.tokenRefreshedDate,
          DateTime.now().toIso8601String(),
        );

        return newAccessToken.toString();
      }

      // If refresh fails (e.g., invalid refresh token), clear session
      await sessionExpiryHandler.clearSession();
      return null;
    } catch (e) {
      // If refresh fails (e.g., refresh token expired), clear session
      await sessionExpiryHandler.clearSession();
      return null;
    }
  }
}
