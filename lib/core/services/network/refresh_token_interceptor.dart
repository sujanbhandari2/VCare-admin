import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/config/api_endpoints.dart';
import 'package:flutter_template/core/config/flavor/configuration.dart';
import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

/// Interceptor that handles 401 Unauthorized errors by attempting to refresh the JWT token.
/// Also auto-refreshes the token if the last refresh was more than or equal to 2 hours ago.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required this.config,
    required this.storageService,
    required this.dio,
  });

  final Configuration config;
  final StorageService storageService;
  final Dio dio;

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
      await _clearSession();
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

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if ([200, 201].contains(response.statusCode)) {
        final data = response.data;

        final tokenData = data['data'];
        final newAccessToken =
            tokenData['accessToken'] ?? tokenData['access_token'];
        final newRefreshToken =
            tokenData['refreshToken'] ?? tokenData['refresh_token'];

        if (newAccessToken == null || newRefreshToken == null) {
          await _clearSession();
          return null;
        }

        await storageService.set(StorageKeys.loggedInUserToken, newAccessToken);
        await storageService.set(
          StorageKeys.loggedInUserRefreshToken,
          newRefreshToken,
        );
        await storageService.set(
          StorageKeys.tokenRefreshedDate,
          DateTime.now().toIso8601String(),
        );

        return newAccessToken;
      }

      // If refresh fails (e.g., invalid refresh token), clear session
      await _clearSession();
      return null;
    } catch (e) {
      // If refresh fails (e.g., refresh token expired), clear session
      await _clearSession();
      return null;
    }
  }

  Future<void> _clearSession() async {
    final sessionKeys = [
      StorageKeys.loggedInUserToken,
      StorageKeys.loggedInUserRefreshToken,
      StorageKeys.loggedInUserId,
      StorageKeys.loggedInUserProfileId,
      StorageKeys.loggedInUserEmail,
      StorageKeys.loggedInUserUsername,
      StorageKeys.tokenRefreshedDate,
      StorageKeys.lastSyncedFcmToken,
    ];

    for (final key in sessionKeys) {
      await storageService.remove(key);
    }

    // Try to navigate to the login screen
    try {
      AppRouter.rootNavigatorKey.currentContext?.goNamed(
        AppRouter.login.toPathName,
      );
    } catch (_) {}
  }
}
