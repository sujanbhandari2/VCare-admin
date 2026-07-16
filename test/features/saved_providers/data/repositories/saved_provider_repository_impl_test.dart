import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/data/repositories/saved_provider_repository_impl.dart';
import 'package:vcare_admin/features/saved_providers/domain/entities/saved_provider.dart';

class _FakeApiClient implements ApiClient {
  _FakeApiClient({
    this.getResponse,
    this.postResponse,
    this.deleteResponse,
  });

  Response<dynamic>? getResponse;
  Response<dynamic>? postResponse;
  Response<dynamic>? deleteResponse;

  String? lastDeletePath;
  Map<String, dynamic>? lastPostBody;

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
  }) =>
      throw UnimplementedError();

  @override
  Future<Response<dynamic>> delete(
    String path, {
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) async {
    lastDeletePath = path;
    return deleteResponse!;
  }

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
    if (body is JsonRequestBody) {
      lastPostBody = body.data;
    }
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
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();
}

Response<dynamic> _ok(dynamic data) => Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 200,
      data: data,
    );

void main() {
  group('SavedProviderRepositoryImpl', () {
    test('fetchSavedProviders maps list response', () async {
      final apiClient = _FakeApiClient(
        getResponse: _ok([
          {
            'linkId': 'link-1',
            'savedAt': '2026-07-06T05:48:15.030Z',
            'provider': {
              'id': 'provider-1',
              'npi': '1234567890',
              'addressLine1': '123 Main St',
              'city': 'Austin',
              'state': 'TX',
              'postalCode': '78701',
              'firstName': 'Jane',
              'lastName': 'Doe',
              'entityCode': 'I',
              'type': 'Physician',
            },
          },
        ]),
      );
      final repository = SavedProviderRepositoryImpl(apiClient);

      final result = await repository.fetchSavedProviders();

      result.when(
        failure: (_) => fail('expected success'),
        success: (providers) {
          expect(providers, hasLength(1));
          expect(providers.single.linkId, 'link-1');
          expect(providers.single.provider.npi, '1234567890');
        },
      );
    });

    test('saveProvider posts mapped payload and parses response', () async {
      final apiClient = _FakeApiClient(
        postResponse: _ok({
          'linkId': 'link-2',
          'savedAt': '2026-07-06T05:48:15.030Z',
          'provider': {
            'id': 'provider-2',
            'npi': '1234567890',
            'addressLine1': '123 Main St',
            'city': 'Austin',
            'state': 'TX',
            'postalCode': '78701',
            'firstName': 'Jane',
            'lastName': 'Doe',
            'entityCode': 'I',
            'type': 'Physician',
          },
        }),
      );
      final repository = SavedProviderRepositoryImpl(apiClient);
      const row = MedicareProviderLookupRow(
        npi: '1234567890',
        firstName: 'Jane',
        lastOrOrgName: 'Doe',
        providerType: 'Physician',
        entityCode: 'I',
        street1: '123 Main St',
        city: 'Austin',
        state: 'TX',
        zip5: '78701',
      );

      final result = await repository.saveProvider(row: row);

      expect(apiClient.lastPostBody?['npi'], '1234567890');
      expect(apiClient.lastPostBody?['lastName'], 'Doe');
      result.when(
        failure: (_) => fail('expected success'),
        success: (SavedProvider provider) {
          expect(provider.linkId, 'link-2');
          expect(provider.provider.npi, '1234567890');
        },
      );
    });

    test('deleteSavedProvider calls provider id path', () async {
      final apiClient = _FakeApiClient(
        deleteResponse: _ok(null),
      );
      final repository = SavedProviderRepositoryImpl(apiClient);

      final result = await repository.deleteSavedProvider(
        providerId: 'd097abd5-c2a9-4371-b646-0d0a90b6326b',
      );

      expect(
        apiClient.lastDeletePath,
        'providers/save/d097abd5-c2a9-4371-b646-0d0a90b6326b',
      );
      result.when(
        failure: (_) => fail('expected success'),
        success: (deleted) => expect(deleted, isTrue),
      );
    });
  });
}
