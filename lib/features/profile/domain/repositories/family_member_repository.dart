import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/profile/domain/entities/family_member.dart';

abstract class FamilyMemberRepository {
  Future<EitherResponseOrException<List<FamilyMember>>> fetchFamilyMembers({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<String>> uploadFamilyMemberProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<FamilyMember>> createFamilyMember({
    required String fullName,
    required String relationship,
    required String gender,
    required String dateOfBirth,
    String? profileId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<FamilyMember>> updateFamilyMember({
    required String id,
    required String fullName,
    required String relationship,
    required String gender,
    required String dateOfBirth,
    String? profileId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<bool>> deleteFamilyMember({
    required String id,
    CancelToken? cancelToken,
  });
}
