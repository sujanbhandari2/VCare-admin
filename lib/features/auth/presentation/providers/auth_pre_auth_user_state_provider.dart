import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/auth_pre_auth_user_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'auth_pre_auth_user_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthPreAuthUserStateNotifier extends _$AuthPreAuthUserStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  AuthPreAuthUserState build() => const AuthPreAuthUserState();

  Future<void> fetchPreAuthUser({
    required String registrationToken,
    void Function(AuthPreAuthUser result)? onCompleted,
    void Function(String? error)? onError,
    CancelToken? cancelToken,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      return;
    }

    _requestCompleter = Completer<void>();

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref.read(authRepositoryProvider).getPreAuthUser(
          registrationToken: registrationToken,
          cancelToken: cancelToken,
        );

    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onError?.call(error.userMessage);
      },
      success: (result) async {
        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(result);
      },
    );

    _completeRequest();
  }

  void _completeRequest() {
    if (_requestCompleter?.isCompleted == false) {
      _requestCompleter?.complete();
    }
  }
}
