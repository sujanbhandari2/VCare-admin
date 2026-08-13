import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/account/data/mappers/account_mapper.dart';
import 'package:vcare_admin/features/account/domain/entities/updated_account_user.dart';
import 'package:vcare_admin/features/account/presentation/providers/account_repository_provider.dart';
import 'package:vcare_admin/features/account/presentation/state/account_edit_state.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_photo_editor.dart';
import 'package:vcare_admin/features/account/utils/account_validators.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'account_edit_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AccountEditStateNotifier extends _$AccountEditStateNotifier {
  @override
  AccountEditState build() => const AccountEditState();

  void reset() {
    if (ref.mounted) {
      state = state.idle();
    }
  }

  /// Saves profile fields and optional photo using web account APIs:
  /// - Photo: `POST files` then `PATCH users/:id` `{ profileId }`
  /// - Name/email: `PATCH users/:id` `{ firstName, lastName, email }`
  Future<UpdatedAccountUser?> saveProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? photoUrl,
    bool photoChanged = false,
    bool photoRemoved = false,
    CancelToken? cancelToken,
  }) async {
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final normalizedEmail = email.trim().toLowerCase();

    final firstError = AccountValidators.validateFirstName(trimmedFirst);
    final lastError = AccountValidators.validateLastName(trimmedLast);
    final emailError = AccountValidators.validateEmail(normalizedEmail);
    if (firstError != null || lastError != null || emailError != null) {
      if (ref.mounted) {
        state = state.failure(firstError ?? lastError ?? emailError);
      }
      return null;
    }

    final userId = ref.read(adminAuthSessionProvider).user?.id.trim() ??
        ref.read(authMeStateProvider).user?.id?.trim() ??
        '';
    if (userId.isEmpty) {
      if (ref.mounted) {
        state = state.failure('Could not determine your account id.');
      }
      return null;
    }

    if (ref.mounted) {
      state = state.loading();
    }

    final repository = ref.read(accountRepositoryProvider);

    if (photoRemoved) {
      final photoResponse = await repository.updateProfilePhoto(
        userId: userId,
        profileId: null,
        cancelToken: cancelToken,
      );
      final photoFailed = photoResponse.when(
        failure: (error) {
          if (ref.mounted) {
            state = state.failure(error.userMessage);
          }
          return true;
        },
        success: (_) => false,
      );
      if (photoFailed) {
        return null;
      }
    } else if (photoChanged && isLocalAccountPhotoPath(photoUrl)) {
      final photoPath = photoUrl!.trim();
      late final List<int> bytes;
      try {
        bytes = await File(photoPath).readAsBytes();
      } on FileSystemException catch (error) {
        if (ref.mounted) {
          state = state.failure(
            error.message.isNotEmpty
                ? error.message
                : 'Could not read the selected photo.',
          );
        }
        return null;
      }

      final uploadResponse = await repository.uploadProfilePhoto(
        bytes: bytes,
        fileName: p.basename(photoPath),
        cancelToken: cancelToken,
      );

      final uploaded = uploadResponse.when(
        failure: (error) {
          if (ref.mounted) {
            state = state.failure(error.userMessage);
          }
          return null;
        },
        success: (file) => file,
      );
      if (uploaded == null) {
        return null;
      }

      final photoResponse = await repository.updateProfilePhoto(
        userId: userId,
        profileId: uploaded.id,
        cancelToken: cancelToken,
      );
      final photoFailed = photoResponse.when(
        failure: (error) {
          if (ref.mounted) {
            state = state.failure(error.userMessage);
          }
          return true;
        },
        success: (_) => false,
      );
      if (photoFailed) {
        return null;
      }
    }

    final response = await repository.updateProfile(
      userId: userId,
      firstName: trimmedFirst,
      lastName: trimmedLast,
      email: normalizedEmail,
      cancelToken: cancelToken,
    );

    return response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        return Future<UpdatedAccountUser?>.value(null);
      },
      success: (updated) async {
        final sessionUser = ref.read(adminAuthSessionProvider).user;
        if (sessionUser != null) {
          await ref
              .read(adminAuthSessionProvider.notifier)
              .patchUser(updated.toPatchedAuthUser(sessionUser));
        }

        ref.read(authMeStateProvider.notifier).applyAccountProfileUpdate(
              firstName: updated.firstName ?? trimmedFirst,
              lastName: updated.lastName ?? trimmedLast,
              email: updated.email,
            );

        // Refresh auth/me so avatar URLs match the new profileId attachment.
        if (photoChanged || photoRemoved) {
          await ref
              .read(authMeStateProvider.notifier)
              .fetchMe(forceRefresh: true, cancelToken: cancelToken);
        } else {
          final local = ref.read(localProfileStateProvider);
          await ref.read(localProfileStateProvider.notifier).save(
                local.copyWith(
                  firstName: updated.firstName ?? trimmedFirst,
                  lastName: updated.lastName ?? trimmedLast,
                  email: updated.email,
                ),
              );
        }

        if (ref.mounted) {
          state = state.success(updated);
        }
        return updated;
      },
    );
  }
}
