import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/presentation/providers/logged_in_user_profile_id_provider.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';
import 'package:vcare_admin/features/profile/presentation/providers/user_profile_repository_provider.dart';
import 'package:vcare_admin/features/profile/presentation/state/user_profile_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'user_profile_state_provider.g.dart';

/// UserProfileStateNotifier
///
@Riverpod(keepAlive: true)
class UserProfileStateNotifier extends _$UserProfileStateNotifier {
  /// Completer for confirming request is not send multiple times
  ///
  Completer<void>? _profileRequestCompleter;
  Completer<void>? _profileUpdateCompleter;

  @override
  UserProfileState build() => const UserProfileState();

  /// Method to get the user profile
  ///
  Future<void> fetchProfile({
    int? profileId,
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(UserProfile?)? onCompleted,
  }) async {
    if (_profileRequestCompleter != null &&
        !_profileRequestCompleter!.isCompleted) {
      onCompleted?.call(null);
      return;
    }

    profileId ??= ref.refresh(loggedInUserProfileIdProvider);

    if (profileId == null) {
      onCompleted?.call(null);
      return;
    }

    // Initialize completer
    _profileRequestCompleter = Completer<void>();

    // Update state
    if (ref.mounted) {
      state = state.fetchingInProgress();
    }

    // Making request to fetch the form
    final response = await ref
        .read(userProfileRepositoryProvider)
        .fetchProfile(
          profileId: profileId,
          forceRefresh: forceRefresh,
          cancelToken: cancelToken,
        );

    // After getting response
    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.fetchFailure(error.userMessage);
        }

        // Trigger onCompleted callback
        onCompleted?.call(null);

        // Complete the completer
        _profileRequestCompleter?.complete();
      },
      success: (result) {
        if (ref.mounted) {
          state = state.fetchSuccess(result);
        }

        // Trigger onCompleted callback
        onCompleted?.call(result);

        // Complete the completer
        _profileRequestCompleter?.complete();
      },
    );
  }

  ///Method to update the user profile
  ///
  Future<void> updateUserProfile({
    required int? profileId,
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    bool forceRefresh = true,
    CancelToken? cancelToken,
    void Function(UserProfile?)? onCompleted,
  }) async {
    if (_profileUpdateCompleter != null &&
        !_profileUpdateCompleter!.isCompleted) {
      onCompleted?.call(null);
      return;
    }

    profileId ??= ref.refresh(loggedInUserProfileIdProvider);

    //cached user state profile details to be shown in case of error
    final userDetails = state.profile;

    if (profileId == null) {
      onCompleted?.call(null);
      return;
    }

    // Initialize completer
    _profileUpdateCompleter = Completer<void>();

    // Update state
    if (ref.mounted) {
      state = state.updatingInProgress();
    }

    //Making the request to update the profile
    final response = await ref
        .read(userProfileRepositoryProvider)
        .updateProfile(
          profileId: profileId,
          payloads: payloads,
          medias: medias,
          cancelToken: cancelToken,
        );

    // After getting response
    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.updateFailure(
            error.userMessage,
            fallbackProfile: userDetails,
          );
        }

        // Trigger onCompleted callback
        onCompleted?.call(null);

        // Complete the completer
        _profileUpdateCompleter?.complete();
      },
      success: (result) {
        if (ref.mounted) {
          state = state.updateSuccess(result);
        }

        // Trigger onCompleted callback
        onCompleted?.call(result);

        // Complete the completer
        _profileUpdateCompleter?.complete();
      },
    );
  }
}
