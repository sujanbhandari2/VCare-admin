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
import 'package:vcare_admin/features/documents/data/mappers/agent_file_mapper.dart';
import 'package:vcare_admin/features/documents/data/mappers/document_type_option_mapper.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/documents/data/models/document_type_option_model.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_type_option.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_upload_constants.dart';
import 'package:vcare_admin/features/documents/domain/repositories/documents_repository.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const DocumentsRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<PaginatedResult<AgentFile>>> fetchFiles(
    PaginatedListRequest request, {
    required String agentProfileId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final trimmedProfileId = agentProfileId.trim();
      if (trimmedProfileId.isEmpty) {
        throw HttpException(
          title: 'Missing agent profile',
          message: 'Agent profile is required to load documents',
        );
      }

      final hostBaseUrl = Configuration.of().baseUrl;

      final response = await apiClient.get(
        ApiEndpoints.files,
        queryParameters: {
          ...request.toQueryParameters(),
          'category': DocumentUploadCategories.agent,
          'categoryReferenceId': trimmedProfileId,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return PaginatedResponseParser.parse(
        response,
        (json) => AgentFileModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(hostBaseUrl: hostBaseUrl),
      );
    });
  }

  @override
  Future<EitherResponseOrException<List<DocumentTypeOption>>>
  fetchDocumentTypes({
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.filesDocumentTypes,
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final models = ResponseValidator.parse(
        response,
        DocumentTypeOptionModel.listFromJson,
        dataValidator: (data) => data is Map,
      );

      return models.toEntities();
    });
  }

  @override
  Future<EitherResponseOrException<void>> uploadDocument({
    required String fileName,
    required List<int> bytes,
    required String agentProfileId,
    required String documentType,
    String? note,
    String? date,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final trimmedProfileId = agentProfileId.trim();
      if (trimmedProfileId.isEmpty) {
        throw HttpException(
          title: 'Missing agent profile',
          message: 'Agent profile is required to upload documents',
        );
      }

      final trimmedType = documentType.trim().isEmpty
          ? defaultDocumentTypeLabel
          : documentType.trim();

      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
          fields: {
            'note': note ?? '',
            'date': date ?? todayIsoDate(),
            'category': DocumentUploadCategories.agent,
            'categoryReferenceId': trimmedProfileId,
            'documentType': trimmedType,
          },
          files: [
            FormFile.fromBytes(
              fieldName: 'files',
              bytes: bytes,
              fileName: fileName,
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
  Future<EitherResponseOrException<void>> deleteDocument({
    required String documentId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.file(documentId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<void>> renameDocument({
    required String documentId,
    required String name,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final validationError = documentRenameValidationError(name);
      if (validationError != null) {
        throw HttpException(
          title: 'Invalid file name',
          message: validationError,
        );
      }

      final response = await apiClient.patch(
        ApiEndpoints.file(documentId),
        JsonRequestBody({'name': name.trim()}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<Uint8List>> downloadDocumentContent({
    required String documentId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.download(
        ApiEndpoints.fileContent(documentId),
        queryParameters: const {'download': true},
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);

      final data = response.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);

      throw HttpException(
        title: 'Invalid Response',
        message: 'Expected binary file content.',
        responseData: data,
      );
    });
  }
}
