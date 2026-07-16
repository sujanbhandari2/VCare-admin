import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/profile/data/mappers/family_member_mapper.dart';
import 'package:vcare_admin/features/profile/data/models/family_member_model.dart';
import 'package:vcare_admin/features/profile/domain/entities/family_member.dart';
import 'package:vcare_admin/features/profile/domain/repositories/family_member_repository.dart';

class FamilyMemberRepositoryImpl implements FamilyMemberRepository {
  const FamilyMemberRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<FamilyMember>>> fetchFamilyMembers({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.familyMembers,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final models = ResponseValidator.parse(
        response,
        parseFamilyMemberList,
        dataValidator: (data) => data is List,
      );

      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<EitherResponseOrException<String>> uploadFamilyMemberProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.files,
        MultipartFormData(
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
  Future<EitherResponseOrException<FamilyMember>> createFamilyMember({
    required String fullName,
    required String relationship,
    required String gender,
    required String dateOfBirth,
    String? profileId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.familyMembers,
        JsonRequestBody(
          toFamilyMemberPayload(
            fullName: fullName,
            relationship: relationship,
            gender: gender,
            dateOfBirth: dateOfBirth,
            profileId: profileId,
          ),
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        parseFamilyMemberItem,
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<FamilyMember>> updateFamilyMember({
    required String id,
    required String fullName,
    required String relationship,
    required String gender,
    required String dateOfBirth,
    String? profileId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.put(
        ApiEndpoints.familyMember(id),
        JsonRequestBody(
          toFamilyMemberPayload(
            fullName: fullName,
            relationship: relationship,
            gender: gender,
            dateOfBirth: dateOfBirth,
            profileId: profileId,
          ),
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        parseFamilyMemberItem,
        dataValidator: (data) => data is Map,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<bool>> deleteFamilyMember({
    required String id,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.familyMember(id),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final isValid = ResponseValidator.isValidResponse(response);
      if (!isValid) {
        throw HttpException.fromResponse(response);
      }

      return isValid;
    });
  }
}
