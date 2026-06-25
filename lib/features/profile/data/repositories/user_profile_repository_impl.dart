import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_mapper.dart';
import 'package:vcare_admin/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
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
