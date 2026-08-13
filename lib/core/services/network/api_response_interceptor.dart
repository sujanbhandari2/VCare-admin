import 'dart:async';

import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/session_expiry_handler.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

/// Interceptor that handles the standard API response structure.
///
/// If success is false, rejects with a [DioException].
/// If success is true, preserves pagination in [Response.extra] and unwraps `data`.
///
/// Also force-logs out when the API reports "Session not found" or "Invalid token".
class ApiResponseInterceptor extends Interceptor {
  ApiResponseInterceptor({this.sessionExpiryHandler});

  final SessionExpiryHandler? sessionExpiryHandler;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final dynamic data = response.data;

    if (data is Map) {
      final map = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);

      if (map.containsKey('success') && map['success'] is bool) {
        final bool success = map['success'] as bool;

        if (!success) {
          final apiMessage = map['message'];
          if (SessionExpiryHandler.normalizedExpiredMessage(apiMessage) !=
                  null &&
              sessionExpiryHandler != null) {
            // Fire before reject — CacheInterceptor may swallow the error path.
            unawaited(
              sessionExpiryHandler!.handleFromApiMessage(apiMessage),
            );
          }

          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: apiMessage ?? 'API Error',
            ),
            true,
          );
          return;
        }

        final pagination = map['pagination'];
        if (pagination is Map<String, dynamic>) {
          response.extra[PaginatedResponseParser.paginationExtraKey] =
              pagination;
        } else if (pagination is Map) {
          response.extra[PaginatedResponseParser.paginationExtraKey] =
              Map<String, dynamic>.from(pagination);
        }

        final metrics = map['metrics'];
        if (metrics is Map<String, dynamic>) {
          response.extra[PaginatedResponseParser.metricsExtraKey] = metrics;
        } else if (metrics is Map) {
          response.extra[PaginatedResponseParser.metricsExtraKey] =
              Map<String, dynamic>.from(metrics);
        }

        if (map.containsKey('data')) {
          final d = map['data'];

          if (d != null) {
            response.data = d;
          } else {
            response.data = {'success': true, 'message': map['message']};
          }
        }
      }
    }
    handler.next(response);
  }
}
