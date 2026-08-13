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

  void backToCredentials() {
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      phase: AdminLoginPhase.credentials,
      tenantOptions: const [],
      clearError: true,
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
              );
            }
          case AdminLoginAuthenticated(:final session):
            await ref
                .read(adminAuthSessionProvider.notifier)
                .setSession(session);
            ref.invalidate(userLoggedInStateProvider);

            if (ref.mounted) {
              state = const AdminLoginState();
            }
            onAuthenticated?.call(session);
        }
      },
    );

    _requestCompleter?.complete();
  }
}
