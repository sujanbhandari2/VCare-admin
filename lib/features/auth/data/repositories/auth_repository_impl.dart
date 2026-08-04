import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:vcare_admin/core/services/network/models/form_file.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/logger.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/auth/data/auth_api_headers.dart';
import 'package:vcare_admin/features/auth/data/mappers/auth_mappers.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_pre_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_identify_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_verify_otp_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_setup_account_result.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';
import 'package:vcare_admin/features/auth/domain/repositories/auth_repository.dart';

import '../models/auth_pre_auth_user_model.dart';
import '../models/auth_login_result_model.dart';
import '../models/auth_identify_result_model.dart';
import '../models/auth_setup_account_result_model.dart';
import '../models/auth_verify_otp_result_model.dart';
import '../models/forgot_password_response_model.dart';
import '../models/login_response_model.dart';
import '../models/register_response_model.dart';

class AuthRepositoryImpl extends AuthRepository {
  /// API Client Instance
  final ApiClient apiClient;
  final StorageService storage;

  /// Constructor
  AuthRepositoryImpl(this.apiClient, this.storage);

  @override
  Future<EitherResponseOrException<AuthIdentifyResult>> identify({
    required String identifier,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.authIdentify,
        JsonRequestBody({'identifier': identifier}),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: AuthApiHeaders.agent,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => AuthIdentifyResultModel.fromJson(data),
        dataValidator: (data) => data is Map,
      );
      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<void>> requestOtp({
    required String identifier,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.authRequestOtp,
        JsonRequestBody({'identifier': identifier}),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: AuthApiHeaders.agent,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<AuthVerifyOtpResult>> verifyOtp({
    required String identifier,
    required String otp,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.authVerifyOtp,
        JsonRequestBody({'identifier': identifier, 'otp': otp}),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: AuthApiHeaders.agent,
      );

      final model = ResponseValidator.parse(
        response,
        (data) {
          if (data is Map<String, dynamic>) {
            return AuthVerifyOtpResultModel.fromJson(data);
          }
          return AuthVerifyOtpResultModel();
        },
        dataValidator: (data) => data == null || data is Map,
      );
      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<AuthPreAuthUser>> getPreAuthUser({
    required String registrationToken,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.authPreAuthUser,
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: {
          ...AuthApiHeaders.agent,
          'x-pre-auth-session-token': registrationToken,
        },
      );

      final model = ResponseValidator.parse(
        response,
        (data) => AuthPreAuthUserModel.fromJson(data),
        dataValidator: (data) => data is Map,
      );
      return model.toEntity();
    });
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
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.authSetupAccount,
        JsonRequestBody({
          'firstName': firstName,
          if (middleName != null && middleName.trim().isNotEmpty)
            'middleName': middleName.trim(),
          'lastName': lastName,
          'password': password,
          if (dob != null && dob.trim().isNotEmpty) 'dob': dob.trim(),
          if (zipCode != null && zipCode.trim().isNotEmpty)
            'zipCode': zipCode.trim(),
          'email': email,
          'phone': phone,
          if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
          if (primaryCity != null && primaryCity.trim().isNotEmpty)
            'primaryCity': primaryCity.trim(),
          if (primaryState != null && primaryState.trim().isNotEmpty)
            'primaryState': primaryState.trim(),
          'tenantSlug': tenantSlug,
        }),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: {
          ...AuthApiHeaders.agent,
          'x-pre-auth-session-token': registrationToken,
        },
      );

      final model = ResponseValidator.parse(
        response,
        (data) => AuthSetupAccountResultModel.fromJson(data),
        dataValidator: (data) => data is Map,
      );
      return model.toEntity();
    });
  }

  /// Password login — returns a session or a 2FA challenge.
  ///
  @override
  Future<EitherResponseOrException<AuthLoginOutcome>> login({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final headers = await AuthApiHeaders.agentWith(
        storage: storage,
        includeDeviceId: true,
      );
      final response = await apiClient.post(
        ApiEndpoints.login,
        JsonRequestBody(payloads),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: headers,
      );

      final loginResultModel = ResponseValidator.parse(
        response,
        (data) => AuthLoginResultModel.fromJson(data),
        dataValidator: (data) => data is Map,
      );
      return loginResultModel.toOutcome();
    });
  }

  @override
  Future<EitherResponseOrException<void>> send2fa({
    required String challengeToken,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.authSend2fa,
        JsonRequestBody({'challengeToken': challengeToken}),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: AuthApiHeaders.agent,
      );

      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<AuthSession>> verify2fa({
    required String challengeToken,
    required String otp,
    bool rememberMe = false,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final headers = await AuthApiHeaders.agentWith(
        storage: storage,
        includeDeviceId: true,
      );
      final response = await apiClient.post(
        ApiEndpoints.authVerify2fa,
        JsonRequestBody({
          'challengeToken': challengeToken,
          'otp': otp,
          'rememberMe': rememberMe,
        }),
        cancelToken: cancelToken,
        isAuthenticated: false,
        additionalHeaders: headers,
      );

      final loginResultModel = ResponseValidator.parse(
        response,
        (data) => AuthLoginResultModel.fromJson(data),
        dataValidator: (data) => data is Map,
      );
      return loginResultModel.toSession();
    });
  }

  /// Method to handle google login
  ///
  @override
  Future<EitherResponseOrException<AuthSession>> googleLogin({
    List<String> scopes = const ["email"],
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      // Google Auth related codes to get access token
      final googleSignIn = GoogleSignIn.instance;

      // Initialize google sign in
      await googleSignIn.initialize();

      // Sign out if already signed in
      await googleSignIn.signOut();

      if (!googleSignIn.supportsAuthenticate()) {
        throw HttpException(
          title: "Authentication Unsupported!",
          message: "Not supported google authenticate",
        );
      }

      try {
        final user = await googleSignIn.authenticate(scopeHint: scopes);
        final authorization = await user.authorizationClient
            .authorizationForScopes(scopes);

        // Getting access token
        final accessToken = authorization?.accessToken;

        if (accessToken == null) {
          throw AppRouter
                  .rootNavigatorKey
                  .currentContext
                  ?.appLocalization
                  .google_access_token_getting_err ??
              "Unable to get the access token.";
        }

        final response = await apiClient.post(
          ApiEndpoints.googleLogin,
          JsonRequestBody({"access_token": accessToken}),
          cancelToken: cancelToken,
          isAuthenticated: false,
        );

        final loginResponseModel = ResponseValidator.parse(
          response,
          (data) => LoginResponseModel.fromJson(data),
        );
        return loginResponseModel.toEntity();
      } on GoogleSignInException catch (e) {
        throw HttpException(title: e.code.name, message: e.description);
      }
    });
  }

  /// Method to handle apple login
  ///
  @override
  Future<EitherResponseOrException<AuthSession>> appleLogin({
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      // Getting apple id credentials
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Getting identity token from credentials
      final identityToken = credential.identityToken;

      // Logging identity token for debugging
      Logger.logMessage("Apple Identity Token: $identityToken");

      // If identity token is null
      if (identityToken == null) {
        throw AppRouter
                .rootNavigatorKey
                .currentContext
                ?.appLocalization
                .apple_identity_token_getting_err ??
            "Unable to get the identity token.";
      }

      final response = await apiClient.post(
        ApiEndpoints.appleLogin,
        JsonRequestBody({"access_token": identityToken}),
        cancelToken: cancelToken,
        isAuthenticated: false,
      );

      final loginResponseModel = ResponseValidator.parse(
        response,
        (data) => LoginResponseModel.fromJson(data),
      );
      return loginResponseModel.toEntity();
    });
  }

  /// Method to handle register
  ///
  @override
  Future<EitherResponseOrException<RegisterResponse>> register({
    required Map<String, dynamic> payloads,
    Map<String, dynamic>? medias,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.register,
        MultipartFormData(
          fields: payloads,
          files:
              medias?.keys
                  .map((k) => FormFile(fieldName: k, path: medias[k]))
                  .toList() ??
              const <FormFile>[],
        ),
        cancelToken: cancelToken,
        isAuthenticated: false,
      );

      final registerResponseModel = ResponseValidator.parse(
        response,
        (data) => RegisterResponseModel.fromJson(data),
      );

      return registerResponseModel.toEntity();
    });
  }

  /// Method to handle forgot password
  ///
  @override
  Future<EitherResponseOrException<ForgotPasswordResponse>> forgetPassword({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.forgetPassword,
        JsonRequestBody(payloads),
        cancelToken: cancelToken,
        isAuthenticated: false,
      );

      final forgetPasswordResponseModel = ResponseValidator.parse(
        response,
        (data) => ForgotPasswordResponseModel.fromJson(data),
      );

      return forgetPasswordResponseModel.toEntity();
    });
  }
}
