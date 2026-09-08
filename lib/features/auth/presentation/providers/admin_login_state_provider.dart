import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/admin_login_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'admin_login_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AdminLoginStateNotifier extends _$AdminLoginStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  AdminLoginState build() => const AdminLoginState();

  Future<void> submitCredentials({
    required String email,
    required String password,
    CancelToken? cancelToken,
    void Function(AdminAuthSession session)? onAuthenticated,
    void Function(String? error)? onError,
  }) async {
    await _login(
      email: email,
      password: password,
      cancelToken: cancelToken,
      onAuthenticated: onAuthenticated,
      onError: onError,
      storeCredentials: true,
    );
  }

  Future<void> submitTenant({
    required String tenantSlug,
    CancelToken? cancelToken,
    void Function(AdminAuthSession session)? onAuthenticated,
    void Function(String? error)? onError,
  }) async {
    final email = state.storedEmail;
    final password = state.storedPassword;
    if (email == null || password == null) {
      onError?.call('Missing login credentials. Please sign in again.');
      return;
    }

    await _login(
      email: email,
      password: password,
      tenantSlug: tenantSlug,
      cancelToken: cancelToken,
      onAuthenticated: onAuthenticated,
      onError: onError,
      storeCredentials: false,
    );
  }

  Future<void> verifyTwoFactor({
    required String otp,
    bool rememberMe = false,
    CancelToken? cancelToken,
    void Function(AdminAuthSession session)? onAuthenticated,
    void Function(String? error)? onError,
  }) async {
    final challengeToken = state.challengeToken?.trim();
    if (challengeToken == null || challengeToken.isEmpty) {
      onError?.call('Missing verification challenge. Please sign in again.');
      return;
    }

    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      return;
    }

    _requestCompleter = Completer<void>();

    if (ref.mounted) {
      state = state.copyWith(isSubmitting: true, clearError: true);
    }

    final response = await ref.read(authRepositoryProvider).adminVerify2fa(
          challengeToken: challengeToken,
          otp: otp.trim(),
          rememberMe: rememberMe,
          cancelToken: cancelToken,
        );

    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.userMessage,
          );
        }
        onError?.call(error.userMessage);
      },
      success: (session) async {
        await ref.read(adminAuthSessionProvider.notifier).setSession(session);
        ref.invalidate(userLoggedInStateProvider);
        // Keep isSubmitting true until navigation finishes so the UI does not
        // flash back to the credentials form between verify and home.
        onAuthenticated?.call(session);
        if (ref.mounted) {
          state = const AdminLoginState();
        }
      },
    );

    _requestCompleter?.complete();
  }

  Future<void> sendTwoFactorCode({
    CancelToken? cancelToken,
    void Function()? onSuccess,
    void Function(String? error)? onError,
  }) async {
    final challengeToken = state.challengeToken?.trim();
    if (challengeToken == null || challengeToken.isEmpty) {
      final message = 'Missing verification challenge. Please sign in again.';
      onError?.call(message);
      throw StateError(message);
    }

    if (state.isResending || state.isSubmitting) {
      return;
    }

    if (ref.mounted) {
      state = state.copyWith(isResending: true, clearError: true);
    }

    final response = await ref.read(authRepositoryProvider).adminSend2fa(
          challengeToken: challengeToken,
          cancelToken: cancelToken,
        );

    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(
            isResending: false,
            errorMessage: error.userMessage,
          );
        }
        onError?.call(error.userMessage);
        throw StateError(error.userMessage);
      },
      success: (expiresIn) async {
        if (ref.mounted) {
          state = state.copyWith(
            isResending: false,
            expiresIn: expiresIn,
            clearError: true,
          );
        }
        onSuccess?.call();
      },
    );
  }

  void backToCredentials() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      phase: AdminLoginPhase.credentials,
      tenantOptions: const [],
      clearError: true,
      clearChallenge: true,
    );
  }

  void reset() {
    if (!ref.mounted) {
      return;
    }

    state = const AdminLoginState();
  }

  Future<void> _login({
    required String email,
    required String password,
    String? tenantSlug,
    CancelToken? cancelToken,
    required bool storeCredentials,
    void Function(AdminAuthSession session)? onAuthenticated,
    void Function(String? error)? onError,
  }) async {
    if (_requestCompleter != null && !_requestCompleter!.isCompleted) {
      return;
    }

    _requestCompleter = Completer<void>();

    if (ref.mounted) {
      state = state.copyWith(
        isSubmitting: true,
        clearError: true,
        storedEmail: storeCredentials ? email : state.storedEmail,
        storedPassword: storeCredentials ? password : state.storedPassword,
      );
    }

    final response = await ref.read(authRepositoryProvider).adminLogin(
          email: email,
          password: password,
          tenantSlug: tenantSlug,
          cancelToken: cancelToken,
        );

    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.userMessage,
          );
        }
        onError?.call(error.userMessage);
      },
      success: (outcome) async {
        switch (outcome) {
          case AdminLoginTenantSelectionRequired(:final tenants):
            if (ref.mounted) {
              state = state.copyWith(
                isSubmitting: false,
                phase: AdminLoginPhase.tenantSelection,
                tenantOptions: tenants,
                clearError: true,
                clearChallenge: true,
              );
            }
          case AdminLoginTwoFactorRequired(
              :final challengeToken,
              :final expiresIn,
            ):
            if (ref.mounted) {
              state = state.copyWith(
                isSubmitting: false,
                phase: AdminLoginPhase.twoFactor,
                challengeToken: challengeToken,
                expiresIn: expiresIn,
                clearError: true,
              );
            }
          case AdminLoginAuthenticated(:final session):
            await ref
                .read(adminAuthSessionProvider.notifier)
                .setSession(session);
            ref.invalidate(userLoggedInStateProvider);
            // Keep isSubmitting true until navigation finishes so the UI does
            // not flash back to the credentials form between auth and home.
            onAuthenticated?.call(session);
            if (ref.mounted) {
              state = const AdminLoginState();
            }
        }
      },
    );

    _requestCompleter?.complete();
  }
}
