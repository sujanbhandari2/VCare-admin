import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/auth_identify_state.dart';

part 'auth_identify_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthIdentifyStateNotifier extends _$AuthIdentifyStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  AuthIdentifyState build() => const AuthIdentifyState();

  Future<void> identify({
    required String identifier,
    void Function(AuthIdentifyResult result)? onCompleted,
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

    final response = await ref
        .read(authRepositoryProvider)
        .identify(identifier: identifier, cancelToken: cancelToken);

    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
        onError?.call(error.message);
      },
      success: (result) async {
        if (!result.atLeastOneAccountLoggedIn) {
          final otpResponse = await ref
              .read(authRepositoryProvider)
              .requestOtp(identifier: identifier, cancelToken: cancelToken);

          final otpFailed = otpResponse.when(
            failure: (error) {
              if (ref.mounted) {
                state = state.failure(error.message);
              }
              onError?.call(error.message);
              return true;
            },
            success: (_) => false,
          );

          if (otpFailed) {
            _completeRequest();
            return;
          }
        }

        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(result);
      },
    );

    _completeRequest();
  }

  Future<void> requestOtp({
    required String identifier,
    void Function()? onCompleted,
    void Function(String? error)? onError,
    CancelToken? cancelToken,
  }) async {
    final response = await ref
        .read(authRepositoryProvider)
        .requestOtp(identifier: identifier, cancelToken: cancelToken);

    response.when(
      failure: (error) => onError?.call(error.message),
      success: (_) => onCompleted?.call(),
    );
  }

  void clear() {
    if (ref.mounted) {
      state = state.cleared();
    }
  }

  void _completeRequest() {
    if (_requestCompleter?.isCompleted == false) {
      _requestCompleter?.complete();
    }
  }
}

@Riverpod(keepAlive: true)
class AuthRequestOtpStateNotifier extends _$AuthRequestOtpStateNotifier {
  @override
  AuthRequestOtpState build() => const AuthRequestOtpState();

  Future<void> requestOtp({
    required String identifier,
    void Function()? onCompleted,
    void Function(String? error)? onError,
    CancelToken? cancelToken,
  }) async {
    if (ref.mounted) {
      state = state.loading();
    }

    final response = await ref
        .read(authRepositoryProvider)
        .requestOtp(identifier: identifier, cancelToken: cancelToken);

    response.when(
      failure: (error) {
        if (ref.mounted) {
          state = state.failure(error.message);
        }
        onError?.call(error.message);
      },
      success: (_) {
        if (ref.mounted) {
          state = state.success();
        }
        onCompleted?.call();
      },
    );
  }
}
