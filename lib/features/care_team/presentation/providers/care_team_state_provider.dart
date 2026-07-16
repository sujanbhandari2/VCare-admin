import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_repository_provider.dart';
import 'package:vcare_admin/features/care_team/presentation/state/care_team_state.dart';
import 'package:vcare_admin/features/home/utils/care_team_utils.dart';
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

  Future<void> createContact(
    CareTeamContactInput input, {
    CancelToken? cancelToken,
    void Function(CareTeamMember? member)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.creatingInProgress();
    }

    final repository = ref.read(careTeamRepositoryProvider);

    String? profileId;
    if (_isLocalPhotoPath(input.photoUrl)) {
      final photoPath = input.photoUrl!.trim();
      try {
        final bytes = await File(photoPath).readAsBytes();
        final uploadResponse = await repository.uploadCareTeamProfilePhoto(
          bytes: bytes,
          fileName: p.basename(photoPath),
          cancelToken: cancelToken,
        );

        final uploadedId = uploadResponse.when(
          failure: (error) {
            if (ref.mounted) {
              state = state.createFailure(error.userMessage);
            }
            onCompleted?.call(null);
            return null;
          },
          success: (id) => id,
        );

        if (uploadedId == null) {
          return;
        }
        profileId = uploadedId;
      } on FileSystemException catch (error) {
        if (ref.mounted) {
          state = state.createFailure(
            error.message.isNotEmpty
                ? error.message
                : 'Could not read the selected photo.',
          );
        }
        onCompleted?.call(null);
        return;
      }
    }

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
      profileId: profileId,
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

  void update(String id, CareTeamContactInput input) {
    state = state.withMembers([
      for (final member in state.members)
        if (member.id == id)
          member.copyWith(
            name: input.name,
            role: input.role,
            clearRoleTitle: true,
            email: input.email,
            phone: input.phone,
            website: input.website,
            bio: input.bio,
            photoUrl: input.photoUrl,
            address: input.address,
            policyNumber: input.policyNumber,
            groupNumber: input.groupNumber,
          )
        else
          member,
    ]);
  }

  void remove(String id) {
    state = state.withMembers(
      state.members.where((member) => member.id != id).toList(),
    );
  }
}
