import 'package:dio/dio.dart';

import 'package:flutter_template/core/config/api_endpoints.dart';
import 'package:flutter_template/core/services/network/http_response_validator.dart';
import 'package:flutter_template/core/services/network/api_client.dart';
import 'package:flutter_template/core/services/network/models/form_file.dart';
import 'package:flutter_template/core/services/network/models/request_body.dart';
import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';
import 'package:flutter_template/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:flutter_template/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_template/features/profile/domain/repositories/user_profile_repository.dart';

import '../models/user_profile_model.dart';

class UserProfileRepositoryImpl extends UserProfileRepository {
  /// API Client Instance
  ///
  final ApiClient apiClient;

  /// Constructor
  ///
  UserProfileRepositoryImpl(this.apiClient);

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
