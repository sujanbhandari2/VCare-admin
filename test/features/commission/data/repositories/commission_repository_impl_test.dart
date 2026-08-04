import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/commission/data/repositories/commission_repository_impl.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? getResponse;
  String? lastGetPath;
  Map<String, dynamic>? lastQueryParameters;

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
  }) => throw UnimplementedError();

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
  group('CommissionRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late CommissionRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = CommissionRepositoryImpl(apiClient);
    });

    test('fetchSummary sends status and agencyGroupId when provided', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.agentCommissionSummary,
        ),
        statusCode: 200,
        data: {'totalSales': 500.0, 'totalCommission': null},
      );

      final result = await repository.fetchSummary(
        status: 'PAID',
        agencyGroupId: 'agency-group-1',
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastGetPath, ApiEndpoints.agentCommissionSummary);
      expect(apiClient.lastQueryParameters, {
        'status': 'PAID',
        'agencyGroupId': 'agency-group-1',
      });
      result.when(
        success: (summary) {
          expect(summary.totalSales, 500.0);
          expect(summary.totalCommission, isNull);
          expect(summary.isAgencyGroup, isTrue);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchSummary omits empty optional query params', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.agentCommissionSummary,
        ),
        statusCode: 200,
        data: {'totalSales': 120.0, 'totalCommission': 12.0},
      );

      await repository.fetchSummary(status: '  ', agencyGroupId: '');

      expect(apiClient.lastQueryParameters, isNull);
    });

    test(
      'fetchHistory sends pagination, sort, status, and agencyGroupId',
      () async {
        apiClient.getResponse = Response<dynamic>(
          requestOptions: RequestOptions(
            path: ApiEndpoints.agentCommissionHistory,
          ),
          statusCode: 200,
          data: [
            {
              'id': 'item-1',
              'clientId': 'client-1',
              'transactionId': 'txn-1',
              'commissionValue': null,
              'commissionType': 'PERCENTAGE',
              'commissionAmount': null,
              'status': 'PENDING',
              'createdAt': '2026-07-01T08:00:00.000Z',
            },
          ],
          extra: {
            PaginatedResponseParser.paginationExtraKey: {
              'page': 1,
              'limit': 10,
              'total': 1,
              'totalPages': 1,
              'hasNext': false,
              'hasPrev': false,
            },
          },
        );

        final result = await repository.fetchHistory(
          const PaginatedListRequest(page: 1, limit: 10),
          status: 'PENDING',
          type: 'all',
          agencyGroupId: 'agency-group-1',
        );

        expect(result.isSuccess, isTrue);
        expect(apiClient.lastGetPath, ApiEndpoints.agentCommissionHistory);
        expect(apiClient.lastQueryParameters, {
          'page': 1,
          'limit': 10,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
          'status': 'PENDING',
          'type': 'all',
          'agencyGroupId': 'agency-group-1',
        });
        result.when(
          success: (page) {
            expect(page.items, hasLength(1));
            expect(page.items.first.transactionId, 'txn-1');
            expect(page.items.first.commissionAmount, isNull);
          },
          failure: (_) => fail('expected success'),
        );
      },
    );

    test(
      'fetchSalesHistory sends pagination, transactionDate sort, status, and agencyGroupId',
      () async {
        apiClient.getResponse = Response<dynamic>(
          requestOptions: RequestOptions(path: ApiEndpoints.agentSalesHistory),
          statusCode: 200,
          data: [
            {
              'id': 'sale-1',
              'payerId': 'payer-1',
              'payer': {'id': 'payer-1', 'name': 'Jane Doe'},
              'status': 'PAID',
              'amount': 500.0,
              'currency': 'usd',
              'commissionAmount': null,
              'transactionDate': '2026-07-01T12:00:00.000Z',
            },
          ],
          extra: {
            PaginatedResponseParser.paginationExtraKey: {
              'page': 1,
              'limit': 10,
              'total': 1,
              'totalPages': 1,
              'hasNext': false,
              'hasPrev': false,
            },
          },
        );

        final result = await repository.fetchSalesHistory(
          const PaginatedListRequest(page: 1, limit: 10),
          status: 'PAID',
          agencyGroupId: 'agency-group-1',
        );

        expect(result.isSuccess, isTrue);
        expect(apiClient.lastGetPath, ApiEndpoints.agentSalesHistory);
        expect(apiClient.lastQueryParameters, {
          'page': 1,
          'limit': 10,
          'sortBy': 'transactionDate',
          'sortOrder': 'desc',
          'status': 'PAID',
          'agencyGroupId': 'agency-group-1',
        });
        result.when(
          success: (page) {
            expect(page.items, hasLength(1));
            expect(page.items.first.amount, 500.0);
            expect(page.items.first.commissionAmount, isNull);
            expect(page.items.first.displayPayerName, 'Jane Doe');
          },
          failure: (_) => fail('expected success'),
        );
      },
    );
  });
}
