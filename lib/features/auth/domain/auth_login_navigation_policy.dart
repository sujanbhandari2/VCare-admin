import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';

/// Maps identify API flags to login flow steps.
class AuthLoginNavigationPolicy {
  AuthLoginNavigationPolicy._();

  /// Whether the user should enter the OTP verification step after identify.
  static bool requiresOtpVerification(AuthIdentifyResult result) {
    if (!result.atLeastOneAccountLoggedIn) {
      return true;
    }
    return result.otpSend;
  }

  /// Resolves the post-OTP step from stored identify flags.
  ///
  /// Parity: web `resolvePostOtpStep` — existing users without an active login
  /// go to activate-details; already-logged-in users go to password login.
  static LoginFlowStep resolvePostOtpStep(AuthIdentifyResult result) {
    if (result.atLeastOneAccountLoggedIn) {
      return LoginFlowStep.password;
    }
    if (!result.userExists) {
      return LoginFlowStep.onboard;
    }
    if (result.multipleAccounts) {
      return LoginFlowStep.disambiguate;
    }
    // userExists without login → activate (web ignores otherPendingAccount here)
    return LoginFlowStep.activateDetails;
  }

  /// When already logged in elsewhere, skip OTP and route directly.
  static LoginFlowStep? resolveSkipOtpStep(AuthIdentifyResult result) {
    if (result.atLeastOneAccountLoggedIn) {
      return resolvePostOtpStep(result);
    }
    return null;
  }
}
