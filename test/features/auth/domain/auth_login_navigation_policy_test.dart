import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_login_navigation_policy.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';

void main() {
  group('AuthLoginNavigationPolicy', () {
    test('requiresOtpVerification when account not logged in elsewhere', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: false,
        otherPendingAccount: false,
        otpSend: false,
      );

      expect(AuthLoginNavigationPolicy.requiresOtpVerification(result), isTrue);
    });

    test('requiresOtpVerification when otpSend is true', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: true,
        otherPendingAccount: false,
        otpSend: true,
      );

      expect(AuthLoginNavigationPolicy.requiresOtpVerification(result), isTrue);
    });

    test('resolvePostOtpStep routes new users to onboard', () {
      const result = AuthIdentifyResult(
        userExists: false,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: false,
        otherPendingAccount: false,
        otpSend: true,
      );

      expect(
        AuthLoginNavigationPolicy.resolvePostOtpStep(result),
        LoginFlowStep.onboard,
      );
    });

    test('resolvePostOtpStep routes pending accounts to activate', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: false,
        otherPendingAccount: true,
        otpSend: true,
      );

      expect(
        AuthLoginNavigationPolicy.resolvePostOtpStep(result),
        LoginFlowStep.activate,
      );
    });

    test('resolvePostOtpStep routes multiple accounts to disambiguate', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: true,
        atLeastOneAccountLoggedIn: false,
        otherPendingAccount: false,
        otpSend: true,
      );

      expect(
        AuthLoginNavigationPolicy.resolvePostOtpStep(result),
        LoginFlowStep.disambiguate,
      );
    });

    test('resolvePostOtpStep defaults to password', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: false,
        otherPendingAccount: false,
        otpSend: true,
      );

      expect(
        AuthLoginNavigationPolicy.resolvePostOtpStep(result),
        LoginFlowStep.password,
      );
    });

    test('resolveSkipOtpStep returns step when already logged in elsewhere', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: true,
        otherPendingAccount: false,
        otpSend: false,
      );

      expect(
        AuthLoginNavigationPolicy.resolveSkipOtpStep(result),
        LoginFlowStep.password,
      );
    });

    test('resolveSkipOtpStep returns null when OTP is required', () {
      const result = AuthIdentifyResult(
        userExists: true,
        multipleAccounts: false,
        atLeastOneAccountLoggedIn: false,
        otherPendingAccount: false,
        otpSend: true,
      );

      expect(AuthLoginNavigationPolicy.resolveSkipOtpStep(result), isNull);
    });
  });
}
