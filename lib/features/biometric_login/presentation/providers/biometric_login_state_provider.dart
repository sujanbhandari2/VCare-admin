import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/user_logged_in_state_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_challenge.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';
import 'package:vcare_admin/features/biometric_login/presentation/providers/biometric_login_repository_provider.dart';
import 'package:vcare_admin/features/biometric_login/presentation/state/biometric_login_state.dart';
import 'package:vcare_admin/shared/utils/logger.dart';
import 'package:vcare_admin/shared/state/operation_state.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

class BiometricLoginStateNotifier extends Notifier<BiometricLoginState> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  BiometricLoginState build() => const BiometricLoginState();

  /// [accountId] scopes settings status to the signed-in account. Omit on the
  /// login screen so any single stored credential enables biometric sign-in.
  Future<void> refreshStatus({String? accountId}) async {
    if (!ref.mounted) {
      return;
    }

    state = state.loadingStatus();

    final response = await ref.read(biometricLoginRepositoryProvider).fetchStatus(
          accountId: accountId,
        );
    await response.when<Future<void>>(
      failure: (error) async {
        if (ref.mounted) {
          state = state.statusFailure(error.userMessage);
        }
      },
      success: (status) async {
        if (ref.mounted) {
          state = state.statusSuccess(status);
        }
      },
    );
  }

  Future<void> enroll({
    required String accessToken,
    required String accountId,
    String? accountEmail,
    String? userType,
    String? deviceName,
    void Function(String? error)? onError,
  }) async {
    try {
      final availability = await _biometricAvailabilityMessage();
      if (availability != null) {
        onError?.call(availability);
        return;
      }

      if (accountId.trim().isEmpty) {
        onError?.call('Unable to enroll biometrics without an account id.');
        return;
      }

      final authenticated = await _authenticate(
        reason: 'Confirm biometrics to enable biometric login.',
      );
      if (!authenticated) {
        if (ref.mounted) {
          state = state.clearAction();
        }
        return;
      }

      if (ref.mounted) {
        state = state.actionLoading();
      }

      final response = await ref.read(biometricLoginRepositoryProvider).enroll(
            accessToken: accessToken,
            accountId: accountId,
            accountEmail: accountEmail,
            userType: userType,
            deviceName: deviceName,
          );

      await response.when<Future<void>>(
        failure: (error) async {
          if (ref.mounted) {
            state = state.actionFailure(error.userMessage);
          }
          onError?.call(error.userMessage);
        },
        success: (status) async {
          if (ref.mounted) {
            state = state.statusSuccess(status).clearAction();
          }
        },
      );
    } catch (error, stackTrace) {
      Logger.logError('Biometric enrollment threw: $error');
      Logger.logRaw(stackTrace);
      final message = 'Unable to complete biometric enrollment.';
      if (ref.mounted) {
        state = state.actionFailure(message);
      }
      onError?.call(message);
    } finally {
      if (ref.mounted && state.acting) {
        state = state.clearAction();
      }
    }
  }

  Future<void> login({
    String? userType,
    String? preferredBiometric,
    String? biometricReason,
    Future<void> Function(AdminAuthSession session)? onAuthenticated,
    void Function(String? error)? onError,
  }) async {
    final repository = ref.read(biometricLoginRepositoryProvider);
    try {
      final availability = await _biometricAvailabilityMessage();
      if (availability != null) {
        onError?.call(availability);
        return;
      }

      if (ref.mounted) {
        state = state.actionLoading();
      }

      // Challenge first so CryptoObject signing can finish immediately after
      // biometric success (Android Keystore requires the authenticated Signature).
      Logger.logMessage('Requesting biometric challenge.');
      final challengeResponse = await repository.challenge(userType: userType);
      final challenge = _resolveChallenge(challengeResponse);
      if (challenge == null) {
        Logger.logWarning(
          'Biometric challenge did not resolve into a valid nonce/token.',
        );
        final error = challengeResponse.failureOrNull;
        final message =
            error?.userMessage ?? 'Unable to start biometric login.';
        if (ref.mounted) {
          state = state.actionFailure(message);
        }
        onError?.call(message);
        return;
      }

      Logger.logMessage('Prompting OS biometric authentication.');
      final authResponse = await repository.authenticateForLogin(
        userType: userType,
        preferredBiometric: preferredBiometric,
        reason: biometricReason,
      );
      if (authResponse.isFailure) {
        await repository.cancelLoginAuthentication();
        final error = authResponse.failureOrNull;
        final code = error?.responseData?.toString() ?? '';
        final message = error?.userMessage ??
            'Biometric authentication was cancelled.';

        if (_isReenrollmentRequired(error)) {
          await repository.clearLocalCredential();
          if (ref.mounted) {
            state = state
                .statusSuccess(BiometricLoginStatus.disabled)
                .actionFailure(
                  'Biometric login needs to be set up again. Enable it from Profile.',
                );
          }
          onError?.call(
            'Biometric login needs to be set up again. Enable it from Profile.',
          );
          return;
        }

        if (ref.mounted) {
          state = state.actionFailure(message);
        }
        onError?.call(message);
        Logger.logWarning('Biometric auth failed: $code $message');
        return;
      }

      Logger.logMessage(
        'Biometric confirmed; completing signed login.',
      );

      final loginResponse = await repository.loginWithChallenge(
        challenge: challenge,
        userType: userType,
      );

      final session = _resolveSession(loginResponse);
      if (session == null) {
        Logger.logWarning(
          'Biometric login response did not resolve into a session.',
        );
        await repository.cancelLoginAuthentication();
        final error = loginResponse.failureOrNull;

        if (_isReenrollmentRequired(error)) {
          await repository.clearLocalCredential();
          if (ref.mounted) {
            state = state
                .statusSuccess(BiometricLoginStatus.disabled)
                .actionFailure(
                  'Biometric login needs to be set up again. Enable it from Profile.',
                );
          }
          onError?.call(
            'Biometric login needs to be set up again. Enable it from Profile.',
          );
          return;
        }

        final message =
            error?.userMessage ?? 'Unable to complete biometric login.';
        if (ref.mounted) {
          state = state.actionFailure(message);
        }
        onError?.call(message);
        return;
      }

      await ref.read(adminAuthSessionProvider.notifier).setSession(session);
      ref.invalidate(userLoggedInStateProvider);
      if (onAuthenticated != null) {
        await onAuthenticated(session);
      }
      if (ref.mounted) {
        state = state.actionSuccess();
      }
    } catch (error, stackTrace) {
      Logger.logError('Biometric login threw: $error');
      Logger.logRaw(stackTrace);
      await repository.cancelLoginAuthentication();
      final message = 'Unable to complete biometric login.';
      if (ref.mounted) {
        state = state.actionFailure(message);
      }
      onError?.call(message);
    } finally {
      if (ref.mounted && state.acting) {
        state = state.clearAction();
      }
    }
  }

  bool _isReenrollmentRequired(Object? error) {
    if (error == null) {
      return false;
    }
    final raw = [
      error.toString(),
      if (error is HttpException) error.message,
      if (error is HttpException) error.responseData?.toString(),
    ].whereType<String>().join(' ').toLowerCase();
    return raw.contains('reenrollment_required') ||
        raw.contains('needs to be set up again') ||
        raw.contains('key user not authenticated') ||
        raw.contains('key_user_not_authenticated');
  }

  Future<void> revoke({
    required String accessToken,
    String? userType,
    void Function(String? error)? onError,
    void Function()? onCompleted,
  }) async {
    try {
      if (accessToken.trim().isEmpty) {
        onError?.call('Unable to revoke biometric login without a session.');
        return;
      }

      if (ref.mounted) {
        state = state.actionLoading();
      }

      final response = await ref.read(biometricLoginRepositoryProvider).revoke(
            accessToken: accessToken,
            userType: userType,
          );
      await response.when<Future<void>>(
        failure: (error) async {
          if (ref.mounted) {
            state = state.actionFailure(error.userMessage);
          }
          onError?.call(error.userMessage);
        },
        success: (_) async {
          if (ref.mounted) {
            state = const BiometricLoginState(
              statusOperation: OperationState<BiometricLoginStatus>.success(
                BiometricLoginStatus.disabled,
              ),
              actionOperation: OperationState<void>.success(null),
            );
          }
          onCompleted?.call();
        },
      );
    } catch (error, stackTrace) {
      Logger.logError('Biometric revoke threw: $error');
      Logger.logRaw(stackTrace);
      final message = 'Unable to revoke biometric login.';
      if (ref.mounted) {
        state = state.actionFailure(message);
      }
      onError?.call(message);
    } finally {
      if (ref.mounted && state.acting) {
        state = state.clearAction();
      }
    }
  }

  Future<bool> _authenticate({required String reason}) async {
    try {
      return _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
      );
    } on PlatformException {
      return false;
    } on UnsupportedError {
      return false;
    }
  }

  Future<String?> _biometricAvailabilityMessage() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (!available) {
        return 'No biometric authentication is available on this device.';
      }

      final biometrics = await _localAuth.getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return 'No biometric authentication is enrolled on this device.';
      }

      return null;
    } on PlatformException {
      return 'Unable to check biometric availability right now.';
    } on UnsupportedError {
      return 'Biometric login is not supported on this platform.';
    }
  }

  BiometricChallenge? _resolveChallenge(
    EitherResponseOrException<BiometricChallenge> response,
  ) {
    if (response.isFailure) {
      return null;
    }

    final challenge = response.dataOrNull;
    if (challenge == null) {
      return null;
    }

    if (challenge.challengeToken.trim().isEmpty ||
        challenge.nonce.trim().isEmpty) {
      return null;
    }

    return challenge;
  }

  AdminAuthSession? _resolveSession(
    EitherResponseOrException<AdminAuthSession> response,
  ) {
    if (response.isFailure) {
      return null;
    }

    return response.dataOrNull;
  }
}

final biometricLoginStateProvider =
    NotifierProvider<BiometricLoginStateNotifier, BiometricLoginState>(
  BiometricLoginStateNotifier.new,
);
