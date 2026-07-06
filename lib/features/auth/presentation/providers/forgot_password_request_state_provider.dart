import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/forgot_password_request_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'forgot_password_request_state_provider.g.dart';

/// ForgotPasswordRequestStateNotifier
///
@Riverpod(keepAlive: true)
class ForgotPasswordRequestStateNotifier
    extends _$ForgotPasswordRequestStateNotifier {
  /// Completer for confirming request is not send multiple times
  ///
  Completer<void>? _requestCompleter;

  @override
  ForgotPasswordRequestState build() => const ForgotPasswordRequestState();

  /// Method to handle forgot password
  ///
  Future<void> forgotPassword({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
    void Function(bool success)? onCompleted,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      onCompleted?.call(false);
      return;
    }

    // Initialize the completer
    _requestCompleter = Completer<void>();

    // Update state
    if (ref.mounted) {
      state = state.loading();
    }

    // Getting response from the network or cache
    final response = await ref
        .read(authRepositoryProvider)
        .forgetPassword(payloads: payloads, cancelToken: cancelToken);

    // After getting response
    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }

        // Trigger on completed callback
        onCompleted?.call(false);

        // Showing toast message in case of error
        if (error.userMessage.isNotEmpty) {
          Fluttertoast.showToast(msg: error.userMessage);
        }
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result);
        }

        // Showing toast message in case of success
        if (result.message != null) {
          Fluttertoast.showToast(msg: result.message!);
        }

        // Trigger on completed callback
        onCompleted?.call(true);
      },
    );

    // Complete the completer
    _requestCompleter?.complete();
  }
}
