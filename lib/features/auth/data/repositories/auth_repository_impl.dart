import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:flutter_template/core/services/network/models/form_file.dart';
import 'package:flutter_template/core/services/network/models/request_body.dart';
import 'package:flutter_template/core/services/network/typedefs/response_or_exception.dart';
import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/utils/logger.dart';
import 'package:flutter_template/core/services/network/http_exception.dart';
import 'package:flutter_template/core/services/network/http_response_validator.dart';
import 'package:flutter_template/core/services/network/api_client.dart';
import 'package:flutter_template/core/config/api_endpoints.dart';
import 'package:flutter_template/features/auth/data/mappers/auth_mappers.dart';
import 'package:flutter_template/features/auth/domain/entities/forgot_password_response.dart';
import 'package:flutter_template/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_template/features/auth/domain/entities/register_response.dart';
import 'package:flutter_template/features/auth/domain/repositories/auth_repository.dart';

import '../models/forgot_password_response_model.dart';
import '../models/login_response_model.dart';
import '../models/register_response_model.dart';

class AuthRepositoryImpl extends AuthRepository {
  /// API Client Instance
  final ApiClient apiClient;

  /// Constructor
  AuthRepositoryImpl(this.apiClient);

  /// Method to login
  ///
  @override
  Future<EitherResponseOrException<AuthSession>> login({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.login,
        JsonRequestBody(payloads),
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
