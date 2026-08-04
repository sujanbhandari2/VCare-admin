import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_repository_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/state/care_team_state.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_constants.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_utils.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'care_team_state_provider.g.dart';

typedef CareTeamContactInput = ({
  String name,
  CareTeamRole role,
  String email,
  String phone,
  String? website,
  String bio,
  String? photoUrl,
  String? address,
  String? policyNumber,
  String? groupNumber,
  String? initialProfileId,
});

bool _isLocalPhotoPath(String? photoUrl) {
  final path = photoUrl?.trim();
  if (path == null || path.isEmpty) return false;
  final lower = path.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return false;
  }
  if (lower.startsWith('assets/')) {
    return false;
  }
  return true;
}

@Riverpod(keepAlive: true)
class CareTeamStateNotifier extends _$CareTeamStateNotifier {
  @override
  CareTeamState build() => const CareTeamState();

  CareTeamMember? byId(String id) => state.byId(id);

  Future<void> fetchCareTeam({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(List<CareTeamMember>? members)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(careTeamRepositoryProvider).fetchCareTeam(
          group: careTeamListGroupAgentCareTeam,
          forceRefresh: forceRefresh,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (members) {
        if (ref.mounted) {
          state = state.success(members);
        }
        onCompleted?.call(members);
      },
    );
  }

  Future<void> refresh({CancelToken? cancelToken}) {
    return fetchCareTeam(forceRefresh: true, cancelToken: cancelToken);
  }

  Future<void> fetchMember(
    String id, {
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(CareTeamMember? member)? onCompleted,
  }) async {
    final cached = state.byId(id);
    if (cached != null && !forceRefresh) {
      onCompleted?.call(cached);
      return;
    }

    if (ref.mounted) {
      state = state.memberLoading();
    }

    final response =
        await ref.read(careTeamRepositoryProvider).fetchCareTeamMember(
              id: id,
              forceRefresh: forceRefresh,
              cancelToken: cancelToken,
            );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.memberFailure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (member) {
        if (ref.mounted) {
          state = state.memberSuccess(member);
        }
        onCompleted?.call(member);
      },
    );
  }

  Future<({bool failed, String? profileId, bool setProfileId})>
      _resolveProfileIdForMutation({
    required String? photoUrl,
    required String? initialProfileId,
    required CancelToken? cancelToken,
    required void Function(String message) onUploadFailure,
  }) async {
    final trimmedPhoto = photoUrl?.trim();
    if (trimmedPhoto == null || trimmedPhoto.isEmpty) {
      final hadProfile = initialProfileId?.trim().isNotEmpty == true;
      return (
        failed: false,
        profileId: null,
        setProfileId: hadProfile,
      );
    }

    if (_isLocalPhotoPath(trimmedPhoto)) {
      try {
        final bytes = await File(trimmedPhoto).readAsBytes();
        final uploadResponse =
            await ref.read(careTeamRepositoryProvider).uploadCareTeamProfilePhoto(
                  bytes: bytes,
                  fileName: p.basename(trimmedPhoto),
                  cancelToken: cancelToken,
                );

        return uploadResponse.when(
          failure: (error) {
            onUploadFailure(error.userMessage);
            return (failed: true, profileId: null, setProfileId: false);
          },
          success: (id) => (failed: false, profileId: id, setProfileId: true),
        );
      } on FileSystemException catch (error) {
        onUploadFailure(
          error.message.isNotEmpty
              ? error.message
              : 'Could not read the selected photo.',
        );
        return (failed: true, profileId: null, setProfileId: false);
      }
    }

    return (failed: false, profileId: null, setProfileId: false);
  }

  Future<void> createContact(
    CareTeamContactInput input, {
    CancelToken? cancelToken,
    void Function(CareTeamMember? member)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.creatingInProgress();
    }

    final repository = ref.read(careTeamRepositoryProvider);

    final photoResult = await _resolveProfileIdForMutation(
      photoUrl: input.photoUrl,
      initialProfileId: null,
      cancelToken: cancelToken,
      onUploadFailure: (message) {
        if (ref.mounted) {
          state = state.createFailure(message);
        }
        onCompleted?.call(null);
      },
    );
    if (photoResult.failed) return;

    final response = await repository.createCareTeamMember(
      role: careTeamRoleLabel(input.role),
      name: input.name,
      phone: input.phone,
      email: input.email,
      website: input.website,
      notes: input.bio,
      address: input.address,
      policy: input.policyNumber,
      group: input.groupNumber,
      profileId: photoResult.setProfileId ? photoResult.profileId : null,
      cancelToken: cancelToken,
    );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.createFailure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (member) {
        if (ref.mounted) {
          state = state.createSuccess(member);
        }
        onCompleted?.call(member);
      },
    );
  }

  Future<void> updateContact(
    String id,
    CareTeamContactInput input, {
    CancelToken? cancelToken,
    void Function(CareTeamMember? member)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final photoResult = await _resolveProfileIdForMutation(
      photoUrl: input.photoUrl,
      initialProfileId: input.initialProfileId,
      cancelToken: cancelToken,
      onUploadFailure: (message) {
        if (ref.mounted) {
          state = state.updateFailure(message);
        }
        onCompleted?.call(null);
      },
    );
    if (photoResult.failed) return;

    final response =
        await ref.read(careTeamRepositoryProvider).updateCareTeamMember(
              id: id,
              role: careTeamRoleLabel(input.role),
              name: input.name,
              phone: input.phone,
              email: input.email,
              website: input.website,
              notes: input.bio,
              address: input.address,
              policy: input.policyNumber,
              group: input.groupNumber,
              profileId: photoResult.profileId,
              setProfileId: photoResult.setProfileId,
              cancelToken: cancelToken,
            );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (member) {
        if (ref.mounted) {
          state = state.updateSuccess(member);
        }
        onCompleted?.call(member);
      },
    );
  }

  Future<void> deleteContact(
    String id, {
    CancelToken? cancelToken,
    void Function(bool success)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.deletingInProgress();
    }

    final response =
        await ref.read(careTeamRepositoryProvider).deleteCareTeamMember(
              id: id,
              cancelToken: cancelToken,
            );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.deleteFailure(error.userMessage);
        }
        onCompleted?.call(false);
      },
      success: (_) {
        if (ref.mounted) {
          state = state.deleteSuccess(id);
        }
        onCompleted?.call(true);
      },
    );
  }
}
