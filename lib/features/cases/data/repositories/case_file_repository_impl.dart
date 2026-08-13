import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/data/mappers/case_file_mapper.dart';
import 'package:vcare_admin/features/cases/data/models/case_file_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_file_repository.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class CaseFileRepositoryImpl implements CaseFileRepository {
  const CaseFileRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<CaseFile>>> fetchFiles(
    String caseId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final hostBaseUrl = Configuration.of().baseUrl;

      final response = await apiClient.get(
        ApiEndpoints.files,
        queryParameters: {
          'category': caseFileCategory,
          'categoryReferenceId': caseId,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
          'limit': 100,
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => CaseFileModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(hostBaseUrl: hostBaseUrl),
      );

      return parsed.items;
    });
  }

  @override
  Future<EitherResponseOrException<void>> uploadFiles(
    String caseId,
    String clientId, {
    required List<({String fileName, List<int> bytes})> files,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (files.isEmpty) return;

      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
          fields: {
            'category': caseFileCategory,
            'categoryReferenceId': caseId,
            'subCategoryReferenceId': clientId,
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
    });
  }

  @override
  Future<EitherResponseOrException<void>> addFilesFromUrl(
    String caseId,
    String clientId, {
    required List<CaseNotePublicUrl> urls,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (urls.isEmpty) return;

      final response = await apiClient.post(
        ApiEndpoints.filesFromUrl,
        JsonRequestBody({
          'files': urls
              .map((url) => {'name': url.name, 'url': url.url})
              .toList(growable: false),
          'category': caseFileCategory,
          'categoryReferenceId': caseId,
          'subCategoryReferenceId': clientId,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<List<CaseFile>>> fetchClientProfileFiles(
    String clientId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final hostBaseUrl = Configuration.of().baseUrl;

      final response = await apiClient.get(
        ApiEndpoints.clientFiles(clientId),
        queryParameters: {
          'category': caseFileClientCategory,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
          'limit': 100,
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final parsed = PaginatedResponseParser.parse(
        response,
        (json) => CaseFileModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(hostBaseUrl: hostBaseUrl),
      );

      return parsed.items;
    });
  }

  @override
  Future<EitherResponseOrException<void>> attachProfileFiles(
    String caseId,
    String clientId, {
    required List<CaseFile> files,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      if (files.isEmpty) return;

      final links = <CaseNotePublicUrl>[];
      final uploads = <({String fileName, List<int> bytes})>[];

      for (final file in files) {
        final url = file.url?.trim() ?? '';
        if (url.startsWith('http://') || url.startsWith('https://')) {
          links.add(CaseNotePublicUrl(url: url, name: file.name));
          continue;
        }

        final bytes = await _downloadFileBytes(
          file.id,
          cancelToken: cancelToken,
        );
        uploads.add((fileName: file.name, bytes: bytes));
      }

      if (links.isNotEmpty) {
        final response = await apiClient.post(
          ApiEndpoints.filesFromUrl,
          JsonRequestBody({
            'files': links
                .map((link) => {'name': link.name, 'url': link.url})
                .toList(growable: false),
            'category': caseFileCategory,
            'categoryReferenceId': caseId,
            'subCategoryReferenceId': clientId,
          }),
          isAuthenticated: true,
          cancelToken: cancelToken,
        );
        ResponseValidator.ensureValid(response);
      }

      if (uploads.isNotEmpty) {
        final response = await apiClient.post(
          ApiEndpoints.files,
          MultipartFormData(
            fields: {
              'category': caseFileCategory,
              'categoryReferenceId': caseId,
              'subCategoryReferenceId': clientId,
            },
            files: [
              for (final upload in uploads)
                FormFile.fromBytes(
                  fieldName: 'files',
                  bytes: upload.bytes,
                  fileName: upload.fileName,
                ),
            ],
          ),
          isAuthenticated: true,
          cancelToken: cancelToken,
        );
        ResponseValidator.ensureValid(response);
      }
    });
  }

  @override
  Future<EitherResponseOrException<void>> deleteFile(
    String fileId, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.file(fileId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<List<int>>> downloadFileContent(
    String fileId, {
    bool download = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(
      () => _downloadFileBytes(
        fileId,
        download: download,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<List<int>> _downloadFileBytes(
    String fileId, {
    bool download = true,
    CancelToken? cancelToken,
  }) async {
    final response = await apiClient.download(
      ApiEndpoints.fileContent(fileId),
      queryParameters: {'download': download},
      cancelToken: cancelToken,
    );

    ResponseValidator.ensureValid(response);

    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return data;

    throw HttpException(
      title: 'Invalid Response',
      message: 'Expected binary file content.',
      responseData: data,
    );
  }
}
