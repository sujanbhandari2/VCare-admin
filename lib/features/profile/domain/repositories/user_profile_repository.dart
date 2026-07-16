import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Fetches the current authenticated user profile and menu via `GET auth/me`.
  Future<EitherResponseOrException<AuthMe>> fetchMe({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  /// Uploads a profile photo via `POST files` and returns the uploaded file id.
  Future<EitherResponseOrException<String>> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  });

  /// Updates the current authenticated user via `PATCH auth/me`.
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
