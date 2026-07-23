import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_setup_account_result.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/auth_setup_account_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

part 'auth_setup_account_state_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthSetupAccountStateNotifier extends _$AuthSetupAccountStateNotifier {
  Completer<void>? _requestCompleter;

  @override
  AuthSetupAccountState build() => const AuthSetupAccountState();

  Future<void> setupAccount({
    required String registrationToken,
    required String firstName,
    String? middleName,
    required String lastName,
    required String password,
    required String dob,
    required String zipCode,
    required String email,
    required String phone,
    String tenantSlug = 'default',
    void Function(AuthSetupAccountResult result)? onCompleted,
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

    final response = await ref.read(authRepositoryProvider).setupAccount(
          registrationToken: registrationToken,
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          password: password,
          dob: dob,
          zipCode: zipCode,
          email: email,
          phone: phone,
          tenantSlug: tenantSlug,
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
        await _storeUserData(result);

        if (ref.mounted) {
          state = state.success(result);
          ref.invalidate(userLoggedInStateProvider);
        }
        onCompleted?.call(result);
      },
    );

    _completeRequest();
  }

  Future<void> _storeUserData(AuthSetupAccountResult result) async {
    if (!ref.mounted) {
      return;
    }

    final session = result.session;
    final storageService = ref.read(storageServiceProvider);

    if (session.access != null) {
      await storageService.set(StorageKeys.loggedInUserToken, session.access);
      await storageService.set(
        StorageKeys.loggedInUserRefreshToken,
        session.refresh,
      );
      await storageService.set(StorageKeys.loggedInUserEmail, session.email);
      await storageService.set(
        StorageKeys.loggedInUserUsername,
        session.username,
      );
      await storageService.set(
        StorageKeys.tokenRefreshedDate,
        DateTime.now().toIso8601String(),
      );
      await storageService.set(StorageKeys.alreadyOnboarded, true);
    }

    if (result.profileId != null && result.profileId!.isNotEmpty) {
      await storageService.set(
        StorageKeys.loggedInUserProfileId,
        result.profileId,
      );
    }

    final tenantId = session.tenantId?.trim();
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
