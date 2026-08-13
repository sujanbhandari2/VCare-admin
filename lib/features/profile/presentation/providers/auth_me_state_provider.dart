import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_to_local_profile_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
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

/// Result of [AuthMeStateNotifier.updateMe].
enum UpdateMeOutcome {
  /// Sparse body was empty and no photo upload was needed.
  noChanges,

  /// PATCH succeeded (and auth/me was refreshed).
  success,

  /// Upload or PATCH failed; see [AuthMeState.error].
  failure,
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
          final tenantId = authMe.user.currentTenant?.id?.trim();
          if (tenantId != null && tenantId.isNotEmpty) {
            await ref.read(storageServiceProvider).set(
                  StorageKeys.loggedInUserTenantId,
                  tenantId,
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

  /// Uploads a new local photo (if any), then PATCHes `auth/me` with a sparse
  /// [body]. When [photoUrl] is a local file path, the file is uploaded to
  /// `POST files` first and the returned file id is set as `profileId`.
  Future<UpdateMeOutcome> updateMe({
    required Map<String, dynamic> body,
    String? photoUrl,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    final repository = ref.read(userProfileRepositoryProvider);
    final payload = Map<String, dynamic>.from(body);

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
          return UpdateMeOutcome.failure;
        }
        payload['profileId'] = uploadedId;
      } on FileSystemException catch (error) {
        if (ref.mounted) {
          state = state.updateFailure(
            error.message.isNotEmpty
                ? error.message
                : 'Could not read the selected photo.',
          );
        }
        return UpdateMeOutcome.failure;
      }
    }

    if (payload.isEmpty) {
      if (ref.mounted) {
        state = state.updateSuccess();
      }
      return UpdateMeOutcome.noChanges;
    }

    final response = await repository.updateMe(
      body: payload,
      cancelToken: cancelToken,
    );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(error.userMessage);
        }
        return UpdateMeOutcome.failure;
      },
      success: (_) async {
        if (ref.mounted) {
          state = state.updateSuccess();
        }
        await fetchMe(forceRefresh: true, cancelToken: cancelToken);
        return UpdateMeOutcome.success;
      },
    );
  }

  /// Applies name/email from a self-service `PATCH users/:id` into cached auth/me.
  void applyAccountProfileUpdate({
    required String firstName,
    required String lastName,
    required String email,
  }) {
    final current = state.data;
    if (current == null || !ref.mounted) {
      return;
    }

    final patched = current.copyWith(
      user: current.user.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
      ),
    );
    state = state.success(patched);
  }
}
