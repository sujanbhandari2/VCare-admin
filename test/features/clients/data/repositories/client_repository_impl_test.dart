import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/features/clients/data/repositories/client_repository_impl.dart';
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? getResponse;
  String? lastGetPath;
  Map<String, dynamic>? lastQueryParameters;

  @override
  String get baseUrl => 'https://example.com/api/v1/';

  @override
  Map<String, String> get headers => const {};

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
  Future<Response<dynamic>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    void Function(int count, int total)? onReceiveProgress,
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
  group('ClientRepositoryImpl.fetchClients', () {
    late _FakeApiClient apiClient;
    late ClientRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = ClientRepositoryImpl(apiClient);
    });

    test('calls GET /clients with GROUP list params', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.clients),
        statusCode: 200,
        data: [
          {
            'id': 'group-1',
            'clientType': 'GROUP',
            'companyName': 'Acme Health LLC',
            'contact': {
              'email': 'billing@acmehealth.com',
              'cellPhone': '+15551234567',
            },
            'address': {'city': 'Austin', 'state': 'TX'},
          },
        ],
        extra: {
          'pagination': {
            'page': 1,
            'limit': 1,
            'total': 1,
            'totalPages': 1,
            'hasNext': false,
            'hasPrev': false,
          },
        },
      );

      final response = await repository.fetchClients(
        const ClientsListRequest(
          page: 1,
          limit: 1,
          clientType: ClientListType.group,
        ),
      );

      expect(apiClient.lastGetPath, ApiEndpoints.clients);
      expect(apiClient.lastQueryParameters, {
        'page': 1,
        'limit': 1,
        'clientType': 'GROUP',
        'sortBy': 'companyName',
        'sortOrder': 'asc',
      });

      response.when(
        failure: (_) => fail('expected success'),
        success: (result) {
          expect(result.items, hasLength(1));
          expect(result.items.first.fullName, 'Acme Health LLC');
          expect(result.items.first.email, 'billing@acmehealth.com');
          expect(result.pagination.total, 1);
        },
      );
    });

    test('calls GET /clients with INDIVIDUAL defaults', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.clients),
        statusCode: 200,
        data: [],
        extra: {
          'pagination': {
            'page': 1,
            'limit': 20,
            'total': 0,
            'totalPages': 0,
            'hasNext': false,
            'hasPrev': false,
          },
        },
      );

      await repository.fetchClients(
        const ClientsListRequest(search: 'Aspen'),
      );

      expect(apiClient.lastQueryParameters, {
        'page': 1,
        'limit': 20,
        'clientType': 'INDIVIDUAL',
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
        'search': 'Aspen',
      });
    });
  });

  group('ClientRepositoryImpl detail APIs', () {
    late _FakeApiClient apiClient;
    late ClientRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = ClientRepositoryImpl(apiClient);
    });

    Response<dynamic> _ok({
      required String path,
      required dynamic data,
      Map<String, dynamic>? pagination,
    }) {
      return Response<dynamic>(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: data,
        extra: {
          if (pagination != null) 'pagination': pagination,
        },
      );
    }

    test('fetchClientDetail uses clients/:id for individuals', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.clientById('ind-1'),
        data: {
          'id': 'ind-1',
          'clientType': 'INDIVIDUAL',
          'basicInfo': {
            'firstName': 'Jane',
            'lastName': 'Doe',
            'gender': 'FEMALE',
          },
          'contactInfo': {
            'email': 'jane@example.com',
            'cellPhone': '+15550001111',
          },
        },
      );

      final response = await repository.fetchClientDetail('ind-1');

      expect(apiClient.lastGetPath, ApiEndpoints.clientById('ind-1'));
      response.when(
        failure: (_) => fail('expected success'),
        success: (detail) {
          expect(detail.fullName, 'Jane Doe');
          expect(detail.clientType, ClientListType.individual);
        },
      );
    });

    test('fetchClientDetail uses clients/:id for groups', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.clientById('group-1'),
        data: {
          'id': 'group-1',
          'clientType': 'GROUP',
          'companyName': 'Acme Health LLC',
          'email': 'billing@acmehealth.com',
        },
      );

      final response = await repository.fetchClientDetail(
        'group-1',
        clientType: ClientListType.group,
      );

      expect(apiClient.lastGetPath, ApiEndpoints.clientById('group-1'));
      response.when(
        failure: (_) => fail('expected success'),
        success: (detail) {
          expect(detail.fullName, 'Acme Health LLC');
          expect(detail.clientType, ClientListType.group);
        },
      );
    });

    test('fetchClientMemberships uses associate-membership path', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.enrollmentsAssociateMembership('c1'),
        data: {
          'clientId': 'c1',
          'details': [],
          'totalGroup': 0,
        },
      );

      await repository.fetchClientMemberships('c1');

      expect(
        apiClient.lastGetPath,
        ApiEndpoints.enrollmentsAssociateMembership('c1'),
      );
    });

    test('fetchDependents uses relationships with DEPENDENT type', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.clientRelationships('c1'),
        data: [
          {
            'id': 'rel-1',
            'clientId': 'dep-1',
            'firstName': 'Sam',
            'lastName': 'Doe',
            'relationship': 'SPOUSE',
          },
        ],
        pagination: {
          'page': 1,
          'limit': 20,
          'total': 1,
          'totalPages': 1,
          'hasNext': false,
          'hasPrev': false,
        },
      );

      final response = await repository.fetchDependents(
        'c1',
        const PaginatedListRequest(),
      );

      expect(apiClient.lastGetPath, ApiEndpoints.clientRelationships('c1'));
      expect(apiClient.lastQueryParameters?['type'], 'DEPENDENT');
      response.when(
        failure: (_) => fail('expected success'),
        success: (result) {
          expect(result.items.first.name, 'Sam Doe');
          expect(result.items.first.relation, 'Spouse');
        },
      );
    });

    test('fetchTransactions uses transactions with payerId', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.transactions,
        data: [],
        pagination: {
          'page': 1,
          'limit': 20,
          'total': 0,
          'totalPages': 0,
          'hasNext': false,
          'hasPrev': false,
        },
      );

      await repository.fetchTransactions('c1', const PaginatedListRequest());

      expect(apiClient.lastGetPath, ApiEndpoints.transactions);
      expect(apiClient.lastQueryParameters?['payerId'], 'c1');
    });

    test('fetchCases uses referral-cases with clientId', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.referralCases,
        data: [
          {
            'id': 'case-1',
            'status': 'REQUESTED',
            'type': 'Procedure Cost',
            'createdAt': '2026-06-25T05:58:27.500Z',
            'updatedAt': '2026-06-25T05:58:27.500Z',
          },
          {
            'id': 'case-2',
            'status': 'DELETED',
            'type': 'Gone',
            'createdAt': '2026-06-25T05:58:27.500Z',
          },
        ],
        pagination: {
          'page': 1,
          'limit': 10,
          'total': 2,
          'totalPages': 1,
          'hasNext': false,
          'hasPrev': false,
        },
      );

      final response = await repository.fetchCases(
        'c1',
        const PaginatedListRequest(limit: 10),
      );

      expect(apiClient.lastGetPath, ApiEndpoints.referralCases);
      expect(apiClient.lastQueryParameters?['clientId'], 'c1');
      response.when(
        failure: (_) => fail('expected success'),
        success: (result) {
          expect(result.items, hasLength(1));
          expect(result.items.first.title, 'Procedure Cost');
        },
      );
    });

    test('fetchDocuments uses clients/:id/files', () async {
      apiClient.getResponse = _ok(
        path: ApiEndpoints.clientFiles('c1'),
        data: [],
        pagination: {
          'page': 1,
          'limit': 20,
          'total': 0,
          'totalPages': 0,
          'hasNext': false,
          'hasPrev': false,
        },
      );

      await repository.fetchDocuments('c1', const PaginatedListRequest());

      expect(apiClient.lastGetPath, ApiEndpoints.clientFiles('c1'));
    });
  });
}
