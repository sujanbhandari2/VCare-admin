import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';

abstract class AuthRepository {
  /// Method to login
  ///
  Future<EitherResponseOrException<AuthSession>> login({
    required Map<String, dynamic> payloads,
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
