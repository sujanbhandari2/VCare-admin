import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/care_team/data/mappers/care_team_member_mapper.dart';
import 'package:vcare_admin/features/care_team/data/models/care_team_member_model.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/domain/repositories/care_team_repository.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_constants.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_upload_constants.dart';

class CareTeamRepositoryImpl implements CareTeamRepository {
  const CareTeamRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<CareTeamMember>>> fetchCareTeam({
    String? group,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final groupFilter =
          (group ?? careTeamListGroupAgentCareTeam).trim();
      final response = await apiClient.get(
        ApiEndpoints.careTeam,
        queryParameters: groupFilter.isEmpty
            ? null
            : <String, dynamic>{'group': groupFilter},
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final models = ResponseValidator.parse(
        response,
        parseCareTeamMemberList,
        dataValidator: (data) => data is List,
      );

      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<EitherResponseOrException<CareTeamMember>> fetchCareTeamMember({
    required String id,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.careTeamMember(id),
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CareTeamMemberModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map && data['id'] != null,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<String>> uploadCareTeamProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
          fields: {
            'category': DocumentUploadCategories.careTeam,
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

      final fileId = ResponseValidator.parse(
        response,
        (data) {
          if (data is! List || data.isEmpty) {
            return '';
          }

          for (final entry in data) {
            if (entry is! Map) continue;
            final model = AgentFileModel.fromJson(
              Map<String, dynamic>.from(entry),
            );
            if (model.id.trim().isNotEmpty) {
              return model.id.trim();
            }
          }

          return '';
        },
        dataValidator: (data) => data is List,
      );

      if (fileId.isEmpty) {
        throw HttpException(
          title: 'Invalid Response',
          message: 'Uploaded file id was missing from the response.',
          statusCode: response.statusCode,
          requestMethod: response.requestOptions.method,
          requestUri: response.requestOptions.uri,
          responseData: response.data,
        );
      }

      return fileId;
    });
  }

  @override
  Future<EitherResponseOrException<CareTeamMember>> createCareTeamMember({
    required String role,
    required String name,
    String? phone,
    String? email,
    String? website,
    String? notes,
    String? address,
    String? policy,
    String? group,
    String? profileId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.careTeam,
        JsonRequestBody(
          buildCareTeamCreatePayload(
            role: role,
            name: name,
            phone: phone,
            email: email,
            website: website,
            notes: notes,
            address: address,
            policy: policy,
            group: group,
            profileId: profileId,
          ),
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CareTeamMemberModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map && data['id'] != null,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<CareTeamMember>> updateCareTeamMember({
    required String id,
    required String role,
    required String name,
    String? phone,
    String? email,
    String? website,
    String? notes,
    String? address,
    String? policy,
    String? group,
    String? profileId,
    bool setProfileId = false,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.put(
        ApiEndpoints.careTeamMember(id),
        JsonRequestBody(
          buildCareTeamUpdatePayload(
            role: role,
            name: name,
            phone: phone,
            email: email,
            website: website,
            notes: notes,
            address: address,
            policy: policy,
            group: group,
            profileId: profileId,
            setProfileId: setProfileId,
          ),
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CareTeamMemberModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: (data) => data is Map && data['id'] != null,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<void>> deleteCareTeamMember({
    required String id,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.careTeamMember(id),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) {
        throw HttpException.fromResponse(response);
      }
    });
  }
}
