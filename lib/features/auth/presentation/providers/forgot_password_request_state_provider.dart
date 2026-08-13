import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/forgot_password_request_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'forgot_password_request_state_provider.g.dart';

@Riverpod(keepAlive: true)
class ForgotPasswordRequestStateNotifier
    extends _$ForgotPasswordRequestStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  ForgotPasswordRequestState build() => const ForgotPasswordRequestState();

  Future<void> forgotPassword({
    required String identifier,
    String? accountId,
    String? dob,
    String? zipCode,
    CancelToken? cancelToken,
    void Function(ForgotPasswordResult? result)? onCompleted,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      onCompleted?.call(null);
      return;
    }

    _requestCompleter = Completer<void>();

    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(authRepositoryProvider)
        .forgotPassword(
          identifier: identifier,
          accountId: accountId,
          dob: dob,
          zipCode: zipCode,
          cancelToken: cancelToken,
        );

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }
        onCompleted?.call(null);
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(result);
      },
    );

    _requestCompleter?.complete();
  }
}
