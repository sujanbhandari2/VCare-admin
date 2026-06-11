import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/enums/login_request_type.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_request_state.dart';

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

    // Else if type is apple sign in or password
    final response = type == .password
        ? await ref
              .read(authRepositoryProvider)
              .login(payloads: payloads, cancelToken: cancelToken)
        : type == .google
        ? await ref
              .read(authRepositoryProvider)
              .googleLogin(cancelToken: cancelToken)
        : await ref
              .read(authRepositoryProvider)
              .appleLogin(cancelToken: cancelToken);

    await _handleAuthResponse(response, onSuccess: onSuccess, onError: onError);
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
          state = state.failure(error.message);
        }

        // Trigger on error callback
        onError?.call(error.message);
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
  }

  void _completeRequest() {
    if (_requestCompleter?.isCompleted == false) {
      _requestCompleter?.complete();
    }
  }
}
