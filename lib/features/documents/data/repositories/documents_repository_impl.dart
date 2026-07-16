import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/data/mappers/agent_file_mapper.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/domain/repositories/documents_repository.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

const String agentProfileDocumentCategory = 'DEAL';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const DocumentsRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<PaginatedResult<AgentFile>>> fetchFiles(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final hostBaseUrl = Configuration.of().baseUrl;

      final response = await apiClient.get(
        ApiEndpoints.files,
        queryParameters: {
          ...request.toQueryParameters(),
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
  Future<EitherResponseOrException<void>> uploadDocument({
    required String fileName,
    required List<int> bytes,
    String? note,
    String? date,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
          fields: {
            'note': note ?? '',
            'date': date ?? todayIsoDate(),
            'category': agentProfileDocumentCategory,
            'categoryReferenceId': '',
            'subCategoryReferenceId': '',
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
}
