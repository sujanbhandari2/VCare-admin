import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';
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

  /// Completes account setup after OTP verification for new users.
  Future<EitherResponseOrException<AuthSetupAccountResult>> setupAccount({
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

  /// Method to handle forgot password
  ///
  Future<EitherResponseOrException<ForgotPasswordResponse>> forgetPassword({
    required Map<String, dynamic> payloads,
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
