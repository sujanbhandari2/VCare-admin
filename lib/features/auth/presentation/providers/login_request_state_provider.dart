import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/enums/login_request_type.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_request_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'login_request_state_provider.g.dart';

/// LoginRequestStateNotifier
///
@Riverpod(keepAlive: true)
class LoginRequestStateNotifier extends _$LoginRequestStateNotifier {
  /// Completer for confirming request is not send multiple times
  ///
  Completer<void>? _requestCompleter;

  @override
  LoginRequestState build() => const LoginRequestState();

  /// Method to handle login
  ///
  Future<void> login({
    Map<String, dynamic> payloads = const {},
    LoginRequestType type = LoginRequestType.password,
    void Function(AuthSession session)? onSuccess,
    void Function(AuthLoginTwoFactorChallenge challenge)? onTwoFactorRequired,
    void Function(String? error)? onError,
    CancelToken? cancelToken,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      return;
    }

    // Initialize completer
    _requestCompleter = Completer<void>();

    // Update state
    if (ref.mounted) {
      state = state.loading(type: type);
    }

    if (type == LoginRequestType.password) {
      final response = await ref
          .read(authRepositoryProvider)
          .login(payloads: payloads, cancelToken: cancelToken);

      await response.when<Future<void>>(
        failure: (error) async {
          if (ref.mounted) {
            state = state.failure(error.userMessage);
          }
          onError?.call(error.userMessage);
        },
          success: (outcome) async {
            switch (outcome) {
              case AuthLoginTwoFactorChallenge():
                if (ref.mounted) {
                  state = const LoginRequestState();
                }
                if (onTwoFactorRequired != null) {
                  onTwoFactorRequired(outcome);
                } else {
                  onError?.call('Two-factor authentication is required.');
                }
              case AuthLoginSessionOutcome(:final session):
                if (ref.mounted) {
                  state = state.success(session);
                }
                await _storeUserData(session);
                onSuccess?.call(session);
            }
          },
      );

      _completeRequest();
      return;
    }

    final response = type == LoginRequestType.google
        ? await ref
              .read(authRepositoryProvider)
              .googleLogin(cancelToken: cancelToken)
        : await ref
              .read(authRepositoryProvider)
              .appleLogin(cancelToken: cancelToken);

    await _handleAuthResponse(response, onSuccess: onSuccess, onError: onError);
  }

  /// Completes login after 2FA OTP verification.
  Future<void> verify2fa({
    required String challengeToken,
    required String otp,
    bool rememberMe = false,
    void Function(AuthSession session)? onSuccess,
    void Function(String? error)? onError,
    CancelToken? cancelToken,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      return;
    }

    _requestCompleter = Completer<void>();

    if (ref.mounted) {
      state = state.loading(type: LoginRequestType.password);
    }

    final response = await ref.read(authRepositoryProvider).verify2fa(
      challengeToken: challengeToken,
      otp: otp,
      rememberMe: rememberMe,
      cancelToken: cancelToken,
    );

    await _handleAuthResponse(response, onSuccess: onSuccess, onError: onError);
  }

  /// Resends the 2FA OTP for an active challenge.
  Future<void> send2fa({
    required String challengeToken,
    void Function()? onSuccess,
    void Function(String? error)? onError,
    CancelToken? cancelToken,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      return;
    }

    _requestCompleter = Completer<void>();

    final response = await ref.read(authRepositoryProvider).send2fa(
      challengeToken: challengeToken,
      cancelToken: cancelToken,
    );

    await response.when<Future<void>>(
      failure: (error) async {
        onError?.call(error.userMessage);
      },
      success: (_) async {
        onSuccess?.call();
      },
    );

    _completeRequest();
  }

  /// Method to handle auth response
  ///
  Future<void> _handleAuthResponse(
    EitherResponseOrException<AuthSession> response, {
    void Function(AuthSession session)? onSuccess,
    void Function(String? error)? onError,
  }) async {
    // After getting response
    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.failure(error.userMessage);
        }

        // Trigger on error callback
        onError?.call(error.userMessage);
      },
      success: (result) async {
        if (ref.mounted) {
          state = state.success(result);
        }

        // Store user data to local storage
        await _storeUserData(result);

        // Trigger on success callback
        onSuccess?.call(result);
      },
    );

    // Complete the request
    _completeRequest();
  }

  /// Method to store user data to the hive
  ///
  Future<void> _storeUserData(AuthSession response) async {
    if (!ref.mounted) {
      return;
    }

    final storageService = ref.read(storageServiceProvider);

    if (response.access != null) {
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

    if (response.profileId != null && response.profileId!.isNotEmpty) {
      await storageService.set(
        StorageKeys.loggedInUserProfileId,
        response.profileId,
      );
    }

    final tenantId = response.tenantId?.trim();
    if (tenantId != null && tenantId.isNotEmpty) {
      await storageService.set(StorageKeys.loggedInUserTenantId, tenantId);
    }
  }

  void _completeRequest() {
    if (_requestCompleter?.isCompleted == false) {
      _requestCompleter?.complete();
    }
  }
}
