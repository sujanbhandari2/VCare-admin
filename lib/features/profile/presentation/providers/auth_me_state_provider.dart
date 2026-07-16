import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_to_local_profile_mapper.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_update_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/user_profile_repository_provider.dart';
import 'package:vcare_admin/features/profile/presentation/state/auth_me_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'auth_me_state_provider.g.dart';

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

/// Fetches and caches the current authenticated user from `GET auth/me`.
///
/// On success, syncs the user into [localProfileStateProvider] so home header,
/// profile screen, and ID card reflect real name and photo.
@Riverpod(keepAlive: true)
class AuthMeStateNotifier extends _$AuthMeStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  AuthMeState build() => const AuthMeState();

  Future<void> fetchMe({
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(AuthMe? authMe)? onCompleted,
  }) async {
    final inFlight = _requestCompleter;
    if (inFlight != null && !inFlight.isCompleted) {
      await inFlight.future;
      onCompleted?.call(state.data);
      return;
    }

    _requestCompleter = Completer<void>();

    try {
      if (ref.mounted) {
        state = state.loading();
      }

      final response = await ref.read(userProfileRepositoryProvider).fetchMe(
            forceRefresh: forceRefresh,
            cancelToken: cancelToken,
          );

      await response.when<Future<void>>(
        failure: (error) async {
          if (ref.mounted) {
            state = state.failure(error.userMessage);
          }
          onCompleted?.call(null);
        },
        success: (authMe) async {
          if (ref.mounted) {
            state = state.success(authMe);
          }

          final uuid = authMe.user.id?.trim();
          if (uuid != null && uuid.isNotEmpty) {
            await ref.read(storageServiceProvider).set(
                  StorageKeys.loggedInUserUuid,
                  uuid,
                );
          }
          final email = authMe.user.email?.trim();
          if (email != null && email.isNotEmpty) {
            await ref.read(storageServiceProvider).set(
                  StorageKeys.loggedInUserEmail,
                  email,
                );
          }

          final localProfile = localProfileFromAuthMe(authMe);
          await ref.read(localProfileStateProvider.notifier).save(localProfile);

          onCompleted?.call(authMe);
        },
      );
    } finally {
      if (_requestCompleter?.isCompleted == false) {
        _requestCompleter?.complete();
      }
    }
  }

  /// Uploads a new local photo (if any), then PATCHes `auth/me`.
  ///
  /// When [photoUrl] is a local file path, the file is uploaded to `POST files`
  /// first and the returned file id is sent as `profileId`.
  Future<bool> updateMe({
    required String fullName,
    required String email,
    required String phone,
    required String dateOfBirth,
    String? photoUrl,
    ProfileAddress? address,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final repository = ref.read(userProfileRepositoryProvider);
    final current = state.data;
    final nameParts = _resolveNameParts(fullName: fullName, current: current);
    final gender = _firstNonEmpty([
      current?.user.gender,
      current?.agentProfile?.gender,
    ]);

    String? profileId;
    if (_isLocalPhotoPath(photoUrl)) {
      final photoPath = photoUrl!.trim();
      try {
        final bytes = await File(photoPath).readAsBytes();
        final uploadResponse = await repository.uploadProfilePhoto(
          bytes: bytes,
          fileName: p.basename(photoPath),
          cancelToken: cancelToken,
        );

        final uploadedId = uploadResponse.when(
          failure: (error) {
            if (ref.mounted) {
              state = state.updateFailure(error.userMessage);
            }
            return null;
          },
          success: (id) => id,
        );

        if (uploadedId == null) {
          return false;
        }
        profileId = uploadedId;
      } on FileSystemException catch (error) {
        if (ref.mounted) {
          state = state.updateFailure(
            error.message.isNotEmpty
                ? error.message
                : 'Could not read the selected photo.',
          );
        }
        return false;
      }
    }

    final response = await repository.updateMe(
      firstName: nameParts.firstName,
      middleName: nameParts.middleName,
      lastName: nameParts.lastName,
      email: email,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      profileId: profileId,
      address: address,
      cancelToken: cancelToken,
    );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        return false;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.updateSuccess();
        }
        await fetchMe(forceRefresh: true, cancelToken: cancelToken);
        return true;
      },
    );
  }
}

({String firstName, String? middleName, String lastName}) _resolveNameParts({
  required String fullName,
  AuthMe? current,
}) {
  final trimmed = fullName.trim();
  final user = current?.user;
  final agent = current?.agentProfile;

  final currentDisplay = (agent?.displayName.isNotEmpty == true
          ? agent!.displayName
          : user?.displayName ?? '')
      .trim();

  if (trimmed.isNotEmpty &&
      currentDisplay.isNotEmpty &&
      trimmed == currentDisplay) {
    final first = _firstNonEmpty([agent?.firstName, user?.firstName]) ?? '';
    final middle = _firstNonEmpty([agent?.middleName, user?.middleName]);
    final last = _firstNonEmpty([agent?.lastName, user?.lastName]) ?? '';
    if (first.isNotEmpty || last.isNotEmpty) {
      return (firstName: first, middleName: middle, lastName: last);
    }
  }

  return splitFullName(trimmed);
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}
