import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/reset_password_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_setup_account_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';

abstract class AuthRepository {
  /// Identifies a user by phone or email before OTP login.
  Future<EitherResponseOrException<AuthIdentifyResult>> identify({
    required String identifier,
    CancelToken? cancelToken,
  });

  /// Sends an OTP to the given identifier.
  Future<EitherResponseOrException<void>> requestOtp({
    required String identifier,
    CancelToken? cancelToken,
  });

  /// Verifies an OTP for the given identifier.
  Future<EitherResponseOrException<AuthVerifyOtpResult>> verifyOtp({
    required String identifier,
    required String otp,
    CancelToken? cancelToken,
  });

  /// Fetches pre-auth user profile for onboard form prefill.
  Future<EitherResponseOrException<AuthPreAuthUser>> getPreAuthUser({
    required String registrationToken,
    CancelToken? cancelToken,
  });

  /// Completes account setup after OTP verification for new or activating users.
  Future<EitherResponseOrException<AuthSetupAccountResult>> setupAccount({
    required String registrationToken,
    required String firstName,
    String? middleName,
    required String lastName,
    required String password,
    String? dob,
    String? zipCode,
    required String email,
    required String phone,
    String? gender,
    String? primaryCity,
    String? primaryState,
    String tenantSlug = 'default',
    CancelToken? cancelToken,
  });

  /// Admin console login — returns a session, tenant selection, or 2FA challenge.
  Future<EitherResponseOrException<AdminLoginOutcome>> adminLogin({
    required String email,
    required String password,
    String? tenantSlug,
    CancelToken? cancelToken,
  });

  /// Resends the admin 2FA OTP for an active challenge.
  /// Returns the updated code expiry in seconds.
  Future<EitherResponseOrException<int>> adminSend2fa({
    required String challengeToken,
    CancelToken? cancelToken,
  });

  /// Completes admin login after 2FA OTP verification.
  Future<EitherResponseOrException<AdminAuthSession>> adminVerify2fa({
    required String challengeToken,
    required String otp,
    bool rememberMe = false,
    CancelToken? cancelToken,
  });

  /// Rotates access and refresh tokens.
  Future<EitherResponseOrException<AuthRefreshTokens>> refreshAuthTokens({
    required String refreshToken,
    CancelToken? cancelToken,
  });

  /// Invalidates the refresh token on the server.
  Future<EitherResponseOrException<void>> logoutSession({
    required String refreshToken,
    CancelToken? cancelToken,
  });

  /// Password login — returns a session or a 2FA challenge.
  Future<EitherResponseOrException<AuthLoginOutcome>> login({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  });

  /// Resends the 2FA OTP for an active challenge.
  Future<EitherResponseOrException<void>> send2fa({
    required String challengeToken,
    CancelToken? cancelToken,
  });

  /// Completes login after 2FA OTP verification.
  Future<EitherResponseOrException<AuthSession>> verify2fa({
    required String challengeToken,
    required String otp,
    bool rememberMe = false,
    CancelToken? cancelToken,
  });

  /// Method to handle register
  ///
  Future<EitherResponseOrException<RegisterResponse>> register({
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
  });

  /// Sends a password reset link for the given identifier.
  Future<EitherResponseOrException<ForgotPasswordResult>> forgotPassword({
    required String identifier,
    String? accountId,
    String? dob,
    String? zipCode,
    CancelToken? cancelToken,
  });

  /// Admin console forgot password — sends `{ email }` (web parity).
  Future<EitherResponseOrException<ForgotPasswordResult>> adminForgotPassword({
    required String email,
    CancelToken? cancelToken,
  });

  /// Completes password reset using a token from the reset link.
  Future<EitherResponseOrException<ResetPasswordResult>> resetPassword({
    required String token,
    required String password,
    CancelToken? cancelToken,
  });

  /// Method to handle google login
  ///
  Future<EitherResponseOrException<AuthSession>> googleLogin({
    List<String> scopes = const ["email"],
    CancelToken? cancelToken,
  });

  /// Method to handle apple login
  ///
  Future<EitherResponseOrException<AuthSession>> appleLogin({
    CancelToken? cancelToken,
  });
}
