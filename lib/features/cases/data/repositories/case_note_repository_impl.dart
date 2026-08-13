import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/data/mappers/case_note_mapper.dart';
import 'package:vcare_admin/features/cases/data/models/case_note_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_note_repository.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class CaseNoteRepositoryImpl implements CaseNoteRepository {
  const CaseNoteRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<CaseNote>>> fetchNotes(
    String caseId, {
    String? currentUserId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.referralCaseNotes(caseId),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final notes = ResponseValidator.parse(response, (data) {
        return _extractMapList(data)
            .map(
              (item) => CaseNoteModel.fromJson(item).toEntity(
                currentUserId: currentUserId,
              ),
            )
            .toList(growable: false);
      }, dataValidator: _isListPayload);

      return sortCaseNotesChronologically(notes);
    });
  }

  @override
  Future<EitherResponseOrException<CaseNote>> createNote(
    String caseId, {
    required String note,
    CaseStatus? status,
    String? accessType,
    String? currentUserId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.referralCaseNotes(caseId),
        MultipartFormData(
          fields: {
            'note': note,
            'status': ?status?.multipartValue,
            'accessType': ?accessType,
          },
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CaseNoteModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: CaseNoteModel.isValidApiData,
      );

      return model.toEntity(currentUserId: currentUserId);
    });
  }

  @override
  Future<EitherResponseOrException<CaseNote>> updateNote(
    String caseId,
    String noteId, {
    String? note,
    CaseStatus? status,
    String? accessType,
    String? currentUserId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.referralCaseNote(caseId, noteId),
        MultipartFormData(
          fields: {
            'note': ?note,
            'status': ?status?.multipartValue,
            'accessType': ?accessType,
          },
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CaseNoteModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: CaseNoteModel.isValidApiData,
      );

      return model.toEntity(currentUserId: currentUserId);
    });
  }

  @override
  Future<EitherResponseOrException<void>> deleteNote(
    String caseId,
    String noteId, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.referralCaseNote(caseId, noteId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<List<CaseNoteTagUser>>> fetchTagUsers(
    String caseId, {
    String? search,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final trimmedSearch = search?.trim();
      final response = await apiClient.get(
        ApiEndpoints.referralCaseNoteTagUsers(caseId),
        queryParameters: {
          if (trimmedSearch != null && trimmedSearch.isNotEmpty)
            'search': trimmedSearch,
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => CaseNoteTagUserModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );

      return parsed.items;
    });
  }

  @override
  Future<EitherResponseOrException<void>> uploadNoteAttachments(
    String caseId,
    String noteId, {
    List<({String fileName, List<int> bytes})> files = const [],
    List<CaseNotePublicUrl> publicUrls = const [],
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (files.isNotEmpty) {
        final response = await apiClient.post(
          ApiEndpoints.files,
          MultipartFormData(
            fields: {
              'category': caseFileCategory,
              'categoryReferenceId': caseId,
              'subCategoryReferenceId': noteId,
            },
            files: [
              for (final file in files)
                FormFile.fromBytes(
                  fieldName: 'files',
                  bytes: file.bytes,
                  fileName: file.fileName,
                ),
            ],
          ),
          isAuthenticated: true,
          cancelToken: cancelToken,
        );
        ResponseValidator.ensureValid(response);
      }

      if (publicUrls.isNotEmpty) {
        final response = await apiClient.post(
          ApiEndpoints.filesFromUrl,
          JsonRequestBody({
            'files': publicUrls
                .map((url) => {'name': url.name, 'url': url.url})
                .toList(growable: false),
            'category': caseFileCategory,
            'categoryReferenceId': caseId,
            'subCategoryReferenceId': noteId,
          }),
          isAuthenticated: true,
          cancelToken: cancelToken,
        );
        ResponseValidator.ensureValid(response);
      }
    });
  }
}

bool _isListPayload(dynamic data) {
  if (data is List) return true;
  return data is Map && (data['data'] is List || data['rows'] is List);
}

List<Map<String, dynamic>> _extractMapList(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  if (data is Map) {
    final list = data['data'] ?? data['rows'] ?? data['results'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
  }

  return const [];
}
