import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
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

  int? lastFetchedProfileId;
  int? lastUpdatedProfileId;

  @override
  String get path => '/profiles/';

  @override
  String get path4ProfileUpdate => '/profiles/';

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
