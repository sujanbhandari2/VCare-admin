import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/auth_verify_otp_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'auth_verify_otp_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthVerifyOtpStateNotifier extends _$AuthVerifyOtpStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  AuthVerifyOtpState build() => const AuthVerifyOtpState();

  Future<void> verifyOtp({
    required String identifier,
    required String otp,
    void Function(AuthVerifyOtpResult result)? onCompleted,
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

    final response = await ref.read(authRepositoryProvider).verifyOtp(
          identifier: identifier,
          otp: otp,
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
        final session = result.session;
        if (session?.access != null) {
          await _storeUserData(session!);
        }

        if (ref.mounted) {
          state = state.success(result);
        }
        onCompleted?.call(result);
      },
    );

    _completeRequest();
  }

  Future<void> _storeUserData(AuthSession response) async {
    if (!ref.mounted) {
      return;
    }

    final storageService = ref.read(storageServiceProvider);

    await storageService.set(StorageKeys.loggedInUserToken, response.access);
    await storageService.set(
      StorageKeys.loggedInUserRefreshToken,
      response.refresh,
    );
    await storageService.set(StorageKeys.loggedInUserId, response.userId);
    await storageService.set(StorageKeys.loggedInUserEmail, response.email);
    await storageService.set(
      StorageKeys.loggedInUserUsername,
      response.username,
    );
    await storageService.set(
      StorageKeys.tokenRefreshedDate,
      DateTime.now().toIso8601String(),
    );
  }

  void _completeRequest() {
    if (_requestCompleter?.isCompleted == false) {
      _requestCompleter?.complete();
    }
  }
}
