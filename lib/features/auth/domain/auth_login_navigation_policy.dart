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
  static LoginFlowStep resolvePostOtpStep(AuthIdentifyResult result) {
    if (!result.userExists) {
      return LoginFlowStep.onboard;
    }
    if (result.otherPendingAccount) {
      return LoginFlowStep.activate;
    }
    if (result.multipleAccounts) {
      return LoginFlowStep.disambiguate;
    }
    return LoginFlowStep.password;
  }

  /// When already logged in elsewhere, skip OTP and route directly.
  static LoginFlowStep? resolveSkipOtpStep(AuthIdentifyResult result) {
    if (result.atLeastOneAccountLoggedIn) {
      return resolvePostOtpStep(result);
    }
    return null;
  }
}
