import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';

abstract class CareTeamRepository {
  Future<EitherResponseOrException<List<CareTeamMember>>> fetchCareTeam({
    bool forceRefresh = true,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<String>> uploadCareTeamProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<CareTeamMember>> createCareTeamMember({
    required String role,
    required String name,
    String? phone,
    String? email,
    String? website,
    String? notes,
    String? address,
    String? policy,
    String? group,
    String? profileId,
    CancelToken? cancelToken,
  });
}
