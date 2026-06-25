import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Fetches the current authenticated user profile and menu via `GET auth/me`.
  Future<EitherResponseOrException<AuthMe>> fetchMe({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

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
