import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/todo/data/repositories/todo_repository_impl.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? getResponse;
  Response<dynamic>? postResponse;
  String? lastGetPath;
  String? lastPostPath;
  Map<String, dynamic>? lastQueryParameters;
  bool? lastGetAuthenticated;
  bool? lastPostAuthenticated;
  RequestBody? lastPostBody;

  @override
  String get baseUrl => 'https://example.com/api/v1/';

  @override
  Map<String, String> get headers => const {};

  @override
  Future<Response<dynamic>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    void Function(int count, int total)? onReceiveProgress,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<dynamic>> delete(
    String path, {
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    bool forceRefresh = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastQueryParameters = queryParameters;
    lastGetAuthenticated = isAuthenticated;
    return getResponse!;
  }

  @override
  Future<Response<dynamic>> post(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    lastPostAuthenticated = isAuthenticated;
    return postResponse!;
  }

  @override
  Future<Response<dynamic>> patch(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) => throw UnimplementedError();

  @override
  Future<Response<dynamic>> put(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) => throw UnimplementedError();
}

void main() {
  group('TodoRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late TodoRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = TodoRepositoryImpl(apiClient);
    });

    test('fetchTodos sends authenticated page/limit query', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.todos),
        statusCode: 200,
        data: [
          {
            'id': 'payment-failed:txn-1',
            'type': 'PAYMENT_FAILED',
            'title': 'Payment failed',
            'description': "Jane Doe's payment of USD 99.5 failed",
            'occurredAt': '2026-07-21T05:00:00.000Z',
            'resource': {'type': 'TRANSACTION', 'id': 'txn-1'},
            'details': {
              'transactionId': 'txn-1',
              'payerId': 'payer-1',
              'payerName': 'Jane Doe',
              'amount': '99.5',
              'currency': 'USD',
              'invoiceNumber': 'INV-100',
            },
          },
        ],
        extra: {
          PaginatedResponseParser.paginationExtraKey: {
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
            'hasNext': false,
            'hasPrev': false,
          },
        },
      );

      final result = await repository.fetchTodos(
        const PaginatedListRequest(page: 1, limit: 20),
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastGetPath, ApiEndpoints.todos);
      expect(apiClient.lastGetAuthenticated, isTrue);
      expect(apiClient.lastQueryParameters, {'page': 1, 'limit': 20});
      result.when(
        success: (page) {
          expect(page.items, hasLength(1));
          expect(page.items.first.paymentFailedDetails?.amount, 99.5);
          expect(page.pagination.total, 1);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('chargeTransaction posts empty body to charge endpoint', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.transactionCharge('txn-1'),
        ),
        statusCode: 200,
        data: null,
      );

      final result = await repository.chargeTransaction(transactionId: 'txn-1');

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPostPath, ApiEndpoints.transactionCharge('txn-1'));
      expect(apiClient.lastPostAuthenticated, isTrue);
      expect(apiClient.lastPostBody, isA<EmptyRequestBody>());
    });

    test('fetchTodos failure when response is invalid', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.todos),
        statusCode: 200,
        data: {'unexpected': true},
      );

      final result = await repository.fetchTodos(
        const PaginatedListRequest(page: 1, limit: 20),
      );

      expect(result.isSuccess, isFalse);
    });
  });
}
