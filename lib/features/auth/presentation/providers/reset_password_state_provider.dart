import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/reset_password_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'reset_password_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ResetPasswordStateNotifier extends _$ResetPasswordStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  ResetPasswordState build() => const ResetPasswordState();

  Future<void> resetPassword({
    required String token,
    required String password,
    CancelToken? cancelToken,
    void Function(bool success)? onCompleted,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      onCompleted?.call(false);
      return;
    }

    _requestCompleter = Completer<void>();

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(authRepositoryProvider)
        .resetPassword(
          token: token,
          password: password,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(false);
      },
      success: (result) {
        if (ref.mounted) {
          state = state.completed(result);
        }
        onCompleted?.call(true);
      },
    );

    _requestCompleter?.complete();
  }
}
