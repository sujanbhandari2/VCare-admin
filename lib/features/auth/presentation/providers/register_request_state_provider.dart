import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/register_request_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'register_request_state_provider.g.dart';

/// RegisterRequestStateNotifier
///
@Riverpod(keepAlive: true)
class RegisterRequestStateNotifier extends _$RegisterRequestStateNotifier {
  /// Completer for confirming request is not send multiple times
  ///
  Completer<void>? _requestCompleter;

  @override
  RegisterRequestState build() => const RegisterRequestState();

  /// Method to handle register
  ///
  Future<void> register({
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
    void Function(RegisterResponse?)? onCompleted,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      onCompleted?.call(null);
      return;
    }

    // Initialize completer
    _requestCompleter = Completer<void>();

    // Update state
    if (ref.mounted) {
      state = state.loading();
    }

    // Getting response from the network or cache
    final response = await ref
        .read(authRepositoryProvider)
        .register(payloads: payloads, medias: medias, cancelToken: cancelToken);

    // After getting response
    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }

        // Trigger on completed callback
        onCompleted?.call(null);

        // Showing toast message in case of error
        if (error.userMessage.isNotEmpty) {
          Fluttertoast.showToast(msg: error.userMessage);
        }
      },
      success: (result) {
        if (ref.mounted) {
          state = state.success(result, payloads: const {}, files: const {});
        }

        // Trigger on completed callback
        onCompleted?.call(result);
      },
    );

    // Complete the completer
    _requestCompleter?.complete();
  }
}
