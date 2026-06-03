import 'package:dio/dio.dart';

import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';
import 'package:flutter_template/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Method to fetch user profile
  ///
  Future<EitherResponseOrException<UserProfile>> fetchProfile({
    required int? profileId,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  /// Method to handle profile update
  ///
  Future<EitherResponseOrException<UserProfile>> updateProfile({
    required int profileId,
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
  });
}
