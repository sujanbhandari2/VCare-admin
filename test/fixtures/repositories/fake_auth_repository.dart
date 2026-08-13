import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_setup_account_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/reset_password_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';
import 'package:vcare_admin/features/auth/domain/repositories/auth_repository.dart';

import '../repository_fixtures.dart';

class FakeAuthRepository implements AuthRepository {
  EitherResponseOrException<AdminLoginOutcome> adminLoginResult = Success(
    AdminLoginAuthenticated(RepositoryFixtures.adminAuthSession()),
  );
  EitherResponseOrException<AuthRefreshTokens> refreshAuthTokensResult =
      Success(
    const AuthRefreshTokens(
      accessToken: 'new-access',
      refreshToken: 'new-refresh',
    ),
  );
  EitherResponseOrException<void> logoutSessionResult = const Success(null);
  EitherResponseOrException<AuthLoginOutcome> loginResult = Success(
    AuthLoginSessionOutcome(RepositoryFixtures.authSession()),
  );
  EitherResponseOrException<AuthSession> verify2faResult = Success(
    RepositoryFixtures.authSession(),
  );
  EitherResponseOrException<void> send2faResult = const Success(null);
  EitherResponseOrException<AuthSession> appleLoginResult = Success(
    RepositoryFixtures.authSession(userId: 12),
  );
  EitherResponseOrException<AuthSession> googleLoginResult = Success(
    RepositoryFixtures.authSession(userId: 13),
  );
  EitherResponseOrException<RegisterResponse> registerResult = Success(
    RepositoryFixtures.registerResponse(),
  );
  EitherResponseOrException<ForgotPasswordResult> forgotPasswordResult =
      Success(RepositoryFixtures.forgotPasswordResult());
  EitherResponseOrException<ResetPasswordResult> resetPasswordResult =
      Success(RepositoryFixtures.resetPasswordResult());
  EitherResponseOrException<AuthIdentifyResult> identifyResult = Success(
    const AuthIdentifyResult(
      userExists: true,
      multipleAccounts: false,
      atLeastOneAccountLoggedIn: false,
      otherPendingAccount: false,
      otpSend: true,
    ),
  );
  EitherResponseOrException<void> requestOtpResult = const Success(null);
  EitherResponseOrException<AuthVerifyOtpResult> verifyOtpResult = Success(
    AuthVerifyOtpResult(session: RepositoryFixtures.authSession()),
  );
  EitherResponseOrException<AuthSetupAccountResult> setupAccountResult =
      Success(
    AuthSetupAccountResult(
      session: RepositoryFixtures.authSession(),
      profileId: 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
    ),
  );
  EitherResponseOrException<AuthPreAuthUser> preAuthUserResult = Success(
    RepositoryFixtures.authPreAuthUser(),
  );

  String? lastAdminLoginEmail;
  String? lastAdminLoginPassword;
  String? lastAdminLoginTenantSlug;
  String? lastLogoutRefreshToken;

  Map<String, dynamic>? lastLoginPayloads;
  Map<String, dynamic>? lastRegisterPayloads;
  String? lastForgotPasswordIdentifier;
  String? lastForgotPasswordAccountId;
  String? lastForgotPasswordDob;
  String? lastForgotPasswordZipCode;
  String? lastResetPasswordToken;
  String? lastResetPasswordPassword;
  String? lastIdentifyIdentifier;
  String? lastRequestOtpIdentifier;
  String? lastVerifyOtpIdentifier;
  String? lastVerifyOtpCode;
  String? lastSetupAccountRegistrationToken;
  String? lastSetupAccountFirstName;
  String? lastSetupAccountLastName;
  String? lastPreAuthUserRegistrationToken;
  String? lastSend2faChallengeToken;
  String? lastVerify2faChallengeToken;
  String? lastVerify2faOtp;
  bool? lastVerify2faRememberMe;

  String get path4AppleLogin => '/auth/apple/';

  String get path4ForgetPassword => '/auth/forgot-password/';

  String get path4GoogleLogin => '/auth/google/';

  String get path4Login => '/auth/login/';

  String get path4Register => '/auth/register/';

  @override
  Future<EitherResponseOrException<AdminLoginOutcome>> adminLogin({
    required String email,
    required String password,
    String? tenantSlug,
    CancelToken? cancelToken,
  }) async {
    lastAdminLoginEmail = email;
    lastAdminLoginPassword = password;
    lastAdminLoginTenantSlug = tenantSlug;
    return adminLoginResult;
  }

  @override
  Future<EitherResponseOrException<AuthRefreshTokens>> refreshAuthTokens({
    required String refreshToken,
    CancelToken? cancelToken,
  }) async {
    return refreshAuthTokensResult;
  }

  @override
  Future<EitherResponseOrException<void>> logoutSession({
    required String refreshToken,
    CancelToken? cancelToken,
  }) async {
    lastLogoutRefreshToken = refreshToken;
    return logoutSessionResult;
  }

  @override
  Future<EitherResponseOrException<AuthIdentifyResult>> identify({
    required String identifier,
    CancelToken? cancelToken,
  }) async {
    lastIdentifyIdentifier = identifier;
    return identifyResult;
  }

  @override
  Future<EitherResponseOrException<void>> requestOtp({
    required String identifier,
    CancelToken? cancelToken,
  }) async {
    lastRequestOtpIdentifier = identifier;
    return requestOtpResult;
  }

  @override
  Future<EitherResponseOrException<AuthVerifyOtpResult>> verifyOtp({
    required String identifier,
    required String otp,
    CancelToken? cancelToken,
  }) async {
    lastVerifyOtpIdentifier = identifier;
    lastVerifyOtpCode = otp;
    return verifyOtpResult;
  }

  @override
  Future<EitherResponseOrException<AuthPreAuthUser>> getPreAuthUser({
    required String registrationToken,
    CancelToken? cancelToken,
  }) async {
    lastPreAuthUserRegistrationToken = registrationToken;
    return preAuthUserResult;
  }

  @override
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
  }) async {
    lastSetupAccountRegistrationToken = registrationToken;
    lastSetupAccountFirstName = firstName;
    lastSetupAccountLastName = lastName;
    return setupAccountResult;
  }

  @override
  Future<EitherResponseOrException<AuthSession>> appleLogin({
    CancelToken? cancelToken,
  }) async {
    return appleLoginResult;
  }

  @override
  Future<EitherResponseOrException<ForgotPasswordResult>> forgotPassword({
    required String identifier,
    String? accountId,
    String? dob,
    String? zipCode,
    CancelToken? cancelToken,
  }) async {
    lastForgotPasswordIdentifier = identifier;
    lastForgotPasswordAccountId = accountId;
    lastForgotPasswordDob = dob;
    lastForgotPasswordZipCode = zipCode;
    return forgotPasswordResult;
  }

  @override
  Future<EitherResponseOrException<ResetPasswordResult>> resetPassword({
    required String token,
    required String password,
    CancelToken? cancelToken,
  }) async {
    lastResetPasswordToken = token;
    lastResetPasswordPassword = password;
    return resetPasswordResult;
  }

  @override
  Future<EitherResponseOrException<AuthSession>> googleLogin({
    List<String> scopes = const ['email'],
    CancelToken? cancelToken,
  }) async {
    return googleLoginResult;
  }

  @override
  Future<EitherResponseOrException<AuthLoginOutcome>> login({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) async {
    lastLoginPayloads = payloads;
    return loginResult;
  }

  @override
  Future<EitherResponseOrException<void>> send2fa({
    required String challengeToken,
    CancelToken? cancelToken,
  }) async {
    lastSend2faChallengeToken = challengeToken;
    return send2faResult;
  }

  @override
  Future<EitherResponseOrException<AuthSession>> verify2fa({
    required String challengeToken,
    required String otp,
    bool rememberMe = false,
    CancelToken? cancelToken,
  }) async {
    lastVerify2faChallengeToken = challengeToken;
    lastVerify2faOtp = otp;
    lastVerify2faRememberMe = rememberMe;
    return verify2faResult;
  }

  @override
  Future<EitherResponseOrException<RegisterResponse>> register({
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
  }) async {
    lastRegisterPayloads = payloads;
    return registerResult;
  }
}
