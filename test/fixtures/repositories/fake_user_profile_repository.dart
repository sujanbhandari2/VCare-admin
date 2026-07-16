import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';
import 'package:vcare_admin/features/profile/domain/repositories/user_profile_repository.dart';

import '../repository_fixtures.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  EitherResponseOrException<UserProfile> fetchResult = Success(
    RepositoryFixtures.userProfile(),
  );
  EitherResponseOrException<UserProfile> updateResult = Success(
    RepositoryFixtures.userProfile(firstName: 'Updated'),
  );
  EitherResponseOrException<AuthMe> fetchMeResult = Success(
    RepositoryFixtures.authMe(),
  );
  EitherResponseOrException<String> uploadProfilePhotoResult = const Success(
    'uploaded-file-id',
  );
  EitherResponseOrException<void> updateMeResult = const Success(null);

  int? lastFetchedProfileId;
  int? lastUpdatedProfileId;
  String? lastUploadedFileName;
  String? lastUpdateMeProfileId;

  @override
  Future<EitherResponseOrException<AuthMe>> fetchMe({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    return fetchMeResult;
  }

  @override
  Future<EitherResponseOrException<String>> uploadProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  }) async {
    lastUploadedFileName = fileName;
    return uploadProfilePhotoResult;
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
  }) async {
    lastUpdateMeProfileId = profileId;
    return updateMeResult;
  }

  @override
  Future<EitherResponseOrException<UserProfile>> fetchProfile({
    required int? profileId,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    lastFetchedProfileId = profileId;
    return fetchResult;
  }

  @override
  Future<EitherResponseOrException<UserProfile>> updateProfile({
    required int profileId,
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
  }) async {
    lastUpdatedProfileId = profileId;
    return updateResult;
  }
}
