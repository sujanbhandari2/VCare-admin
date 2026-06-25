import 'package:dio/dio.dart';

import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

/// Interceptor that handles the standard API response structure.
///
/// If success is false, rejects with a [DioException].
/// If success is true, preserves pagination in [Response.extra] and unwraps `data`.
class ApiResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final dynamic data = response.data;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('success') && data['success'] is bool) {
        final bool success = data['success'] as bool;

        if (!success) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: data['message'] ?? 'API Error',
            ),
            true,
          );
          return;
        }

        final pagination = data['pagination'];
        if (pagination is Map<String, dynamic>) {
          response.extra[PaginatedResponseParser.paginationExtraKey] =
              pagination;
        } else if (pagination is Map) {
          response.extra[PaginatedResponseParser.paginationExtraKey] =
              Map<String, dynamic>.from(pagination);
        }

        if (data.containsKey('data')) {
          final d = data['data'];

          if (d != null) {
            response.data = d;
          } else {
            response.data = {'success': true, 'message': data['message']};
          }
        }
      }
    }
    handler.next(response);
  }
}
