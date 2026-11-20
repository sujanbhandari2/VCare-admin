import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/features/cases/data/repositories/case_repository_impl.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note_summarize.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? postResponse;
  String? lastPostPath;
  RequestBody? lastPostBody;
  bool? lastPostAuthenticated;

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
  group('CaseRepositoryImpl.summarizeCaseNotes', () {
    late _FakeApiClient apiClient;
    late CaseRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = CaseRepositoryImpl(apiClient);
    });

    test('posts to referral-cases/{id}/summarize with notes payload', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.referralCaseSummarize('case-1'),
        ),
        statusCode: 200,
        data: {
          'success': true,
          'summary': 'Patient needs follow-up with PCP.',
        },
      );

      const request = CaseNoteSummarizeRequest(
        notes: [
          CaseNoteSummarizeInput(
            note: 'First note',
            authorName: 'Jane Advocate',
          ),
          CaseNoteSummarizeInput(note: 'Second note'),
        ],
      );

      final result = await repository.summarizeCaseNotes('case-1', request);

      result.when(
        success: (summary) {
          expect(summary, 'Patient needs follow-up with PCP.');
        },
        failure: (_) => fail('expected success'),
      );
      expect(
        apiClient.lastPostPath,
        ApiEndpoints.referralCaseSummarize('case-1'),
      );
      expect(apiClient.lastPostAuthenticated, isTrue);

      final body = (apiClient.lastPostBody as JsonRequestBody).data;
      expect(body['notes'], isA<List>());
      final notes = body['notes'] as List;
      expect(notes, hasLength(2));
      expect(notes[0], {
        'note': 'First note',
        'createdBy': {'name': 'Jane Advocate'},
      });
      expect(notes[1], {'note': 'Second note'});
    });

    test('fails when summary is missing from response', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.referralCaseSummarize('case-1'),
        ),
        statusCode: 200,
        data: {'success': true},
      );

      final result = await repository.summarizeCaseNotes(
        'case-1',
        const CaseNoteSummarizeRequest(
          notes: [CaseNoteSummarizeInput(note: 'Only note')],
        ),
      );

      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) {
          expect(error, isNotNull);
        },
      );
    });
  });
}
