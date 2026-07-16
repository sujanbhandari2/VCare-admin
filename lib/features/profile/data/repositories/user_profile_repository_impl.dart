import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_mapper.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_update_mapper.dart';
import 'package:vcare_admin/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';
import 'package:vcare_admin/features/profile/domain/repositories/user_profile_repository.dart';

import '../models/auth_me_model.dart';
import '../models/user_profile_model.dart';

class UserProfileRepositoryImpl extends UserProfileRepository {
  /// API Client Instance
  ///
  final ApiClient apiClient;

  /// Constructor
  ///
  UserProfileRepositoryImpl(this.apiClient);

  @override
  Future<EitherResponseOrException<AuthMe>> fetchMe({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.authMe,
        isAuthenticated: true,
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final authMeModel = ResponseValidator.parse(
        response,
        (data) => AuthMeModel.fromJson(data as Map<String, dynamic>),
        dataValidator: (data) => data is Map && data['user'] is Map,
      );
      return authMeModel.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<String>> uploadProfilePhoto({
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
  Future<EitherResponseOrException<void>> updateMe({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String phone,
    required String dateOfBirth,
    String? gender,
    String? profileId,
    bool? allowTextNotification,
    ProfileAddress? address,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.authMe,
        JsonRequestBody(
          toUpdateMePayload(
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            email: email,
            phone: phone,
            dateOfBirth: dateOfBirth,
            gender: gender,
            profileId: profileId,
            allowTextNotification: allowTextNotification,
            address: address,
          ),
        ),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  /// Method to fetch user profile
  ///
  @override
  Future<EitherResponseOrException<UserProfile>> fetchProfile({
    required int? profileId,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        '${ApiEndpoints.profile}$profileId',
        forceRefresh: forceRefresh,
        cancelToken: cancelToken,
      );

      final userModel = ResponseValidator.parse(
        response,
        (data) => UserProfileModel.fromJson(data),
        dataValidator: (data) => data is Map && data['id'] != null,
      );
      return userModel.toEntity();
    });
  }

  /// Method to handle profile update
  ///
  @override
  Future<EitherResponseOrException<UserProfile>> updateProfile({
    required int profileId,
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        '${ApiEndpoints.profile}$profileId/',
        MultipartFormData(
          fields: payloads,
          files:
              medias?.keys
                  .map((k) => FormFile(fieldName: k, path: medias[k]))
                  .toList() ??
              const <FormFile>[],
        ),
        cancelToken: cancelToken,
      );

      final userModel = ResponseValidator.parse(
        response,
        (data) => UserProfileModel.fromJson(data),
        dataValidator: (data) => data is Map && data['id'] != null,
      );
      return userModel.toEntity();
    });
  }
}
