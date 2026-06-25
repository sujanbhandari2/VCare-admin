import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';

import 'paginated_result.dart';
import 'pagination_meta.dart';
import 'pagination_meta_model.dart';

/// Parses paginated API responses after [_ApiInterceptor] unwraps `data`.
///
/// Pagination metadata is preserved in [Response.extra] under `pagination`.
class PaginatedResponseParser {
  PaginatedResponseParser._();

  static const String paginationExtraKey = 'pagination';

  static PaginatedResult<T> parse<T>(
    Response<dynamic> response,
    T Function(dynamic json) itemMapper, {
    String listKey = 'data',
  }) {
    ResponseValidator.ensureValid(response);

    final items = _extractItems(response.data, itemMapper, listKey: listKey);
    final pagination = _extractPagination(response);

    return PaginatedResult<T>(items: items, pagination: pagination);
  }

  static List<T> _extractItems<T>(
    dynamic data,
    T Function(dynamic json) itemMapper, {
    required String listKey,
  }) {
    if (data is List) {
      return data.map(itemMapper).toList();
    }

    if (data is Map<String, dynamic>) {
      final list = data[listKey] ?? data['rows'] ?? data['results'];
      if (list is List) {
        return list.map(itemMapper).toList();
      }
    }

    throw HttpException(
      title: 'Invalid Response',
      message: 'Expected a paginated list payload.',
      responseData: data,
    );
  }

  static PaginationMeta _extractPagination(Response<dynamic> response) {
    final raw = response.extra[paginationExtraKey];
    if (raw is Map<String, dynamic>) {
      return PaginationMetaModel.fromJson(raw).toEntity();
    }

    if (raw is Map) {
      return PaginationMetaModel.fromJson(
        Map<String, dynamic>.from(raw),
      ).toEntity();
    }

    // Non-paginated fallback for endpoints that omit pagination metadata.
    final data = response.data;
    final count = data is List
        ? data.length
        : data is Map
        ? _listLength(data)
        : 0;

    return PaginationMeta(
      page: 1,
      limit: count,
      total: count,
      totalPages: count > 0 ? 1 : 0,
      hasNext: false,
      hasPrev: false,
    );
  }

  static int _listLength(Map data) {
    for (final key in ['data', 'rows', 'results']) {
      final value = data[key];
      if (value is List) return value.length;
    }
    return 0;
  }
}
