import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_upload_constants.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? getResponse;
  Response<dynamic>? postResponse;
  Response<dynamic>? patchResponse;
  Response<dynamic>? downloadResponse;
  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  String? lastDownloadPath;
  Map<String, dynamic>? lastQueryParameters;
  Map<String, dynamic>? lastDownloadQueryParameters;
  RequestBody? lastPostBody;
  RequestBody? lastPatchBody;

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
  }) async {
    lastDownloadPath = path;
    lastDownloadQueryParameters = queryParameters;
    return downloadResponse!;
  }

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
  }) async {
    lastPostPath = path;
    lastPostBody = body;
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
  }) async {
    lastPatchPath = path;
    lastPatchBody = body;
    return patchResponse!;
  }

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
  group('DocumentsRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late DocumentsRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = DocumentsRepositoryImpl(apiClient);
    });

    test('fetchDocumentTypes parses key/label map', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.filesDocumentTypes),
        statusCode: 200,
        data: {
          'W9_FORM': 'W-9 Form',
          'OTHER': 'Other',
        },
      );

      final result = await repository.fetchDocumentTypes();

      expect(apiClient.lastGetPath, ApiEndpoints.filesDocumentTypes);
      expect(result.isSuccess, isTrue);
      result.when(
        success: (options) {
          expect(options, hasLength(2));
          expect(options.first.key, 'W9_FORM');
          expect(options.first.label, 'W-9 Form');
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('fetchFiles sends AGENT category and agentProfileId', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.files),
        statusCode: 200,
        data: <dynamic>[],
      );

      final result = await repository.fetchFiles(
        const PaginatedListRequest(page: 1, limit: 20),
        agentProfileId: 'agent-profile-1',
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastGetPath, ApiEndpoints.files);
      expect(apiClient.lastQueryParameters, {
        'page': 1,
        'limit': 20,
        'category': DocumentUploadCategories.agent,
        'categoryReferenceId': 'agent-profile-1',
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      });
    });

    test('fetchFiles fails when agentProfileId is missing', () async {
      final result = await repository.fetchFiles(
        const PaginatedListRequest(page: 1, limit: 20),
        agentProfileId: '  ',
      );

      expect(result.isFailure, isTrue);
      expect(apiClient.lastGetPath, isNull);
    });

    test('uploadDocument sends AGENT fields and documentType label', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.files),
        statusCode: 200,
        data: {'success': true},
      );

      final result = await repository.uploadDocument(
        fileName: 'w9.pdf',
        bytes: const [1, 2, 3],
        agentProfileId: 'agent-profile-1',
        documentType: 'W-9 Form',
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPostPath, ApiEndpoints.files);
      final body = apiClient.lastPostBody;
      expect(body, isA<MultipartFormData>());
      final fields = (body! as MultipartFormData).fields;
      expect(fields['category'], DocumentUploadCategories.agent);
      expect(fields['categoryReferenceId'], 'agent-profile-1');
      expect(fields['documentType'], 'W-9 Form');
    });

    test('renameDocument patches name', () async {
      apiClient.patchResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.file('file-1')),
        statusCode: 200,
        data: {'success': true},
      );

      final result = await repository.renameDocument(
        documentId: 'file-1',
        name: 'renamed.pdf',
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPatchPath, ApiEndpoints.file('file-1'));
      final body = apiClient.lastPatchBody;
      expect(body, isA<JsonRequestBody>());
      expect((body! as JsonRequestBody).data, {'name': 'renamed.pdf'});
    });

    test('renameDocument rejects invalid extension', () async {
      final result = await repository.renameDocument(
        documentId: 'file-1',
        name: 'no-extension',
      );

      expect(result.isFailure, isTrue);
      expect(apiClient.lastPatchPath, isNull);
    });

    test('downloadDocumentContent requests content with download=true', () async {
      apiClient.downloadResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.fileContent('file-1'),
        ),
        statusCode: 200,
        data: Uint8List.fromList(const [1, 2, 3]),
      );

      final result = await repository.downloadDocumentContent(
        documentId: 'file-1',
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastDownloadPath, ApiEndpoints.fileContent('file-1'));
      expect(apiClient.lastDownloadQueryParameters, {'download': true});
      result.when(
        success: (bytes) => expect(bytes, [1, 2, 3]),
        failure: (_) => fail('expected success'),
      );
    });
  });
}
