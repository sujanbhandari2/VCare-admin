import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/core/services/network/api_response_interceptor.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

void main() {
  group('ApiResponseInterceptor', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(ApiResponseInterceptor());
      dio.httpClientAdapter = _FakeAdapter();
    });

    test('preserves pagination in response.extra when unwrapping data', () async {
      final response = await dio.get<dynamic>('/clients');

      expect(response.data, isA<List>());
      expect((response.data as List).length, 1);
      expect(
        response.extra[PaginatedResponseParser.paginationExtraKey],
        isA<Map<String, dynamic>>(),
      );

      final pagination =
          response.extra[PaginatedResponseParser.paginationExtraKey]
              as Map<String, dynamic>;
      expect(pagination['total'], 1);
      expect(pagination['hasNext'], false);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '''
{
  "success": true,
  "message": "ok",
  "data": [{"id": "client-1"}],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  }
}
''',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
