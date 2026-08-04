import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/domain/repositories/care_team_repository.dart';

class FakeCareTeamRepository implements CareTeamRepository {
  EitherResponseOrException<List<CareTeamMember>> fetchResult = const Success(
    [],
  );
  EitherResponseOrException<CareTeamMember> fetchMemberResult = Failure(
    HttpException(
      title: 'Not found',
      message: 'Member not found',
      errorType: HttpErrorType.client,
    ),
  );
  EitherResponseOrException<String> uploadResult = const Success('file-id');
  EitherResponseOrException<CareTeamMember>? createResult;
  EitherResponseOrException<CareTeamMember>? updateResult;
  EitherResponseOrException<void> deleteResult = const Success(null);

  int fetchCallCount = 0;
  int fetchMemberCallCount = 0;
  int uploadCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  String? lastGroup;
  String? lastMemberId;
  String? lastUploadFileName;
  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;

  @override
  Future<EitherResponseOrException<List<CareTeamMember>>> fetchCareTeam({
    String? group,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    fetchCallCount++;
    lastGroup = group;
    return fetchResult;
  }

  @override
  Future<EitherResponseOrException<CareTeamMember>> fetchCareTeamMember({
    required String id,
    bool forceRefresh = true,
    CancelToken? cancelToken,
  }) async {
    fetchMemberCallCount++;
    lastMemberId = id;
    return fetchMemberResult;
  }

  @override
  Future<EitherResponseOrException<String>> uploadCareTeamProfilePhoto({
    required List<int> bytes,
    required String fileName,
    CancelToken? cancelToken,
  }) async {
    uploadCallCount++;
    lastUploadFileName = fileName;
    return uploadResult;
  }

  @override
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
  }) async {
    createCallCount++;
    lastCreateArgs = {
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'website': website,
      'notes': notes,
      'address': address,
      'policy': policy,
      'group': group,
      'profileId': profileId,
    };
    return createResult ??
        Success(
          CareTeamMember(
            id: 'new-id',
            name: name,
            role: CareTeamRole.provider,
            agentId: 'agent-1',
          ),
        );
  }

  @override
  Future<EitherResponseOrException<CareTeamMember>> updateCareTeamMember({
    required String id,
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
    bool setProfileId = false,
    CancelToken? cancelToken,
  }) async {
    updateCallCount++;
    lastUpdateArgs = {
      'id': id,
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'website': website,
      'notes': notes,
      'address': address,
      'policy': policy,
      'group': group,
      'profileId': profileId,
      'setProfileId': setProfileId,
    };
    return updateResult ??
        Success(
          CareTeamMember(
            id: id,
            name: name,
            role: CareTeamRole.provider,
            agentId: 'agent-1',
          ),
        );
  }

  @override
  Future<EitherResponseOrException<void>> deleteCareTeamMember({
    required String id,
    CancelToken? cancelToken,
  }) async {
    deleteCallCount++;
    lastMemberId = id;
    return deleteResult;
  }
}
