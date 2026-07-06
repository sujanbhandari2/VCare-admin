import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_to_local_profile_mapper.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/user_profile_repository_provider.dart';
import 'package:vcare_admin/features/profile/presentation/state/auth_me_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'auth_me_state_provider.g.dart';

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
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      onCompleted?.call(null);
      return;
    }

    _requestCompleter = Completer<void>();

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

        final localProfile = localProfileFromAuthMe(authMe);
        await ref.read(localProfileStateProvider.notifier).save(localProfile);

        onCompleted?.call(authMe);
      },
    );

    _requestCompleter?.complete();
  }
}
