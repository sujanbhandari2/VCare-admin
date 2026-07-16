import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/profile/data/mappers/family_member_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/family_member.dart';
import 'package:vcare_admin/features/profile/domain/repositories/family_member_repository.dart';
import 'package:vcare_admin/features/profile/presentation/providers/family_member_repository_provider.dart';
import 'package:vcare_admin/features/profile/presentation/state/family_members_state.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_family_section.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'family_members_state_provider.g.dart';

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
class FamilyMembersStateNotifier extends _$FamilyMembersStateNotifier {
  @override
  FamilyMembersState build() => const FamilyMembersState();

  List<ProfileFamilyMember> get profileMembers =>
      state.members.map((member) => member.toProfileFamilyMember()).toList();

  FamilyMember? byId(String id) => state.byId(id);

  Future<void> fetchFamilyMembers({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(List<FamilyMember>? members)? onCompleted,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(familyMemberRepositoryProvider)
        .fetchFamilyMembers(
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

  Future<String?> _uploadProfilePhotoIfNeeded({
    required FamilyMemberRepository repository,
    String? photoUrl,
    CancelToken? cancelToken,
    required void Function(String message) onFailure,
  }) async {
    if (!_isLocalPhotoPath(photoUrl)) {
      return null;
    }

    final photoPath = photoUrl!.trim();
    try {
      final bytes = await File(photoPath).readAsBytes();
      final uploadResponse = await repository.uploadFamilyMemberProfilePhoto(
        bytes: bytes,
        fileName: p.basename(photoPath),
        cancelToken: cancelToken,
      );

      return uploadResponse.when(
        failure: (error) {
          onFailure(error.userMessage);
          return null;
        },
        success: (id) => id,
      );
    } on FileSystemException catch (error) {
      onFailure(
        error.message.isNotEmpty
            ? error.message
            : 'Could not read the selected photo.',
      );
      return null;
    }
  }

  Future<bool> createFamilyMember({
    required String name,
    required String relationship,
    required String gender,
    required String dob,
    String? photoUrl,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.withCreating(true);
    }

    final repository = ref.read(familyMemberRepositoryProvider);

    final profileId = await _uploadProfilePhotoIfNeeded(
      repository: repository,
      photoUrl: photoUrl,
      cancelToken: cancelToken,
      onFailure: (message) {
        if (ref.mounted) {
          state = state.withCreating(false).failure(message);
        }
      },
    );

    if (_isLocalPhotoPath(photoUrl) && profileId == null) {
      return false;
    }

    final response = await repository.createFamilyMember(
      fullName: name,
      relationship: relationship,
      gender: gender,
      dateOfBirth: dob,
      profileId: profileId,
      cancelToken: cancelToken,
    );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.withCreating(false).failure(error.userMessage);
        }
        return false;
      },
      success: (_) async {
        await fetchFamilyMembers(
          forceRefresh: true,
          cancelToken: cancelToken,
        );
        if (ref.mounted) {
          state = state.withCreating(false);
        }
        return true;
      },
    );
  }

  Future<bool> updateFamilyMember({
    required String id,
    required String name,
    required String relationship,
    required String gender,
    required String dob,
    String? photoUrl,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.withCreating(true);
    }

    final repository = ref.read(familyMemberRepositoryProvider);

    final profileId = await _uploadProfilePhotoIfNeeded(
      repository: repository,
      photoUrl: photoUrl,
      cancelToken: cancelToken,
      onFailure: (message) {
        if (ref.mounted) {
          state = state.withCreating(false).failure(message);
        }
      },
    );

    if (_isLocalPhotoPath(photoUrl) && profileId == null) {
      return false;
    }

    final response = await repository.updateFamilyMember(
      id: id,
      fullName: name,
      relationship: relationship,
      gender: gender,
      dateOfBirth: dob,
      profileId: profileId,
      cancelToken: cancelToken,
    );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.withCreating(false).failure(error.userMessage);
        }
        return false;
      },
      success: (_) async {
        await fetchFamilyMembers(
          forceRefresh: true,
          cancelToken: cancelToken,
        );
        if (ref.mounted) {
          state = state.withCreating(false);
        }
        return true;
      },
    );
  }

  Future<bool> deleteFamilyMember({
    required String id,
    CancelToken? cancelToken,
  }) async {
    final response = await ref
        .read(familyMemberRepositoryProvider)
        .deleteFamilyMember(
          id: id,
          cancelToken: cancelToken,
        );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        return false;
      },
      success: (_) async {
        await fetchFamilyMembers(
          forceRefresh: true,
          cancelToken: cancelToken,
        );
        return true;
      },
    );
  }
}
