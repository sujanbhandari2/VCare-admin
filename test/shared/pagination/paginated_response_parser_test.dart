import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

void main() {
  group('PaginatedResponseParser', () {
    test('parses list data with pagination from response.extra', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/items'),
        statusCode: 200,
        data: [
          {'id': '1'},
          {'id': '2'},
        ],
        extra: {
          PaginatedResponseParser.paginationExtraKey: {
            'page': 1,
            'limit': 20,
            'total': 2,
            'totalPages': 1,
            'hasNext': false,
            'hasPrev': false,
          },
        },
      );

      final result = PaginatedResponseParser.parse(
        response,
        (json) => (json as Map)['id'] as String,
      );

      expect(result.items, ['1', '2']);
      expect(result.pagination.total, 2);
      expect(result.pagination.hasNext, isFalse);
    });

    test('falls back when pagination metadata is missing', () {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/items'),
        statusCode: 200,
        data: [
          {'id': 'a'},
        ],
      );

      final result = PaginatedResponseParser.parse(
        response,
        (json) => (json as Map)['id'] as String,
      );

      expect(result.items, ['a']);
      expect(result.pagination.total, 1);
      expect(result.pagination.hasNext, isFalse);
    });
  });
}
