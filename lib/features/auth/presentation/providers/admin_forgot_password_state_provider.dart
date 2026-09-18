import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/forgot_password_request_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'admin_forgot_password_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AdminForgotPasswordStateNotifier
    extends _$AdminForgotPasswordStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  ForgotPasswordRequestState build() => const ForgotPasswordRequestState();

  Future<void> requestReset({
    required String email,
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
        .adminForgotPassword(
          email: email.trim().toLowerCase(),
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
          state = state.success(result);
        }
        onCompleted?.call(true);
      },
    );

    _requestCompleter?.complete();
  }

  void reset() {
    if (ref.mounted) {
      state = const ForgotPasswordRequestState();
    }
  }
}
