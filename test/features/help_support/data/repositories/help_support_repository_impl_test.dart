import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/help_support/data/repositories/help_support_repository_impl.dart';
import 'package:vcare_admin/features/help_support/domain/entities/contact_support_attachment.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? postResponse;
  Object? postError;
  String? lastPostPath;
  RequestBody? lastPostBody;
  bool? lastAuthenticated;

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
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    lastAuthenticated = isAuthenticated;
    if (postError != null) throw postError!;
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
  group('HelpSupportRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late HelpSupportRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = HelpSupportRepositoryImpl(apiClient);
    });

    test('posts multipart payload and maps success', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.contactSupport),
        statusCode: 200,
        data: {'type': 'support'},
      );

      final result = await repository.submitContactSupport(
        message: 'Need help with a failed payment',
        context: {
          'page': 'failed-payment',
          'transactionId': 'tx-1',
          'subject': 'Payment Failed',
        },
        files: const [
          ContactSupportAttachment(
            path: '/tmp/screenshot.png',
            fileName: 'screenshot.png',
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.type, 'support');
      expect(apiClient.lastPostPath, ApiEndpoints.contactSupport);
      expect(apiClient.lastAuthenticated, isTrue);

      final body = apiClient.lastPostBody! as MultipartFormData;
      expect(body.fields['type'], 'support');
      expect(body.fields['message'], 'Need help with a failed payment');
      expect(jsonDecode(body.fields['context'] as String), {
        'page': 'failed-payment',
        'transactionId': 'tx-1',
        'subject': 'Payment Failed',
      });
      expect(body.files, hasLength(1));
      expect(body.files.first.key, 'files');
      expect(body.files.first.fileName, 'screenshot.png');
    });

    test('returns failure when response type is missing', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.contactSupport),
        statusCode: 200,
        data: <String, dynamic>{},
      );

      final result = await repository.submitContactSupport(
        message: 'Help please',
      );

      expect(result.isSuccess, isFalse);
      expect(result.failureOrNull, isNotNull);
    });

    test('returns failure when message is empty', () async {
      final result = await repository.submitContactSupport(message: '  ');
      expect(result.isSuccess, isFalse);
      expect(apiClient.lastPostPath, isNull);
    });
  });
}
