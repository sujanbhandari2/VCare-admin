import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/feature_access/data/repositories/feature_access_repository_impl.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? getResponse;
  Object? getError;
  String? lastGetPath;
  bool? lastForceRefresh;

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
    lastForceRefresh = forceRefresh;
    if (getError != null) throw getError!;
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
  group('FeatureAccessRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late FeatureAccessRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = FeatureAccessRepositoryImpl(apiClient);
    });

    test('fetches feature access from settings endpoint', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.settings),
        data: {
          'features': {
            'caseManagement': true,
            'healthChat': false,
            'membership': true,
          },
        },
        statusCode: 200,
      );

      final result = await repository.fetchFeatureAccess(forceRefresh: true);

      expect(apiClient.lastGetPath, ApiEndpoints.settings);
      expect(apiClient.lastForceRefresh, isTrue);
      expect(result, isA<Success<FeatureAccess, HttpException>>());
      final access = (result as Success<FeatureAccess, HttpException>).data;
      expect(access.caseManagement, isTrue);
      expect(access.healthChat, isFalse);
      expect(access.membership, isTrue);
    });
  });
}
