import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/forgot_password_response.dart';
import 'package:vcare_admin/features/auth/domain/entities/register_response.dart';
import 'package:vcare_admin/features/auth/domain/repositories/auth_repository.dart';

import '../repository_fixtures.dart';

class FakeAuthRepository implements AuthRepository {
  EitherResponseOrException<AuthSession> loginResult = Success(
    RepositoryFixtures.authSession(),
  );
  EitherResponseOrException<AuthSession> appleLoginResult = Success(
    RepositoryFixtures.authSession(userId: 12),
  );
  EitherResponseOrException<AuthSession> googleLoginResult = Success(
    RepositoryFixtures.authSession(userId: 13),
  );
  EitherResponseOrException<RegisterResponse> registerResult = Success(
    RepositoryFixtures.registerResponse(),
  );
  EitherResponseOrException<ForgotPasswordResponse> forgotPasswordResult =
      Success(RepositoryFixtures.forgotPasswordResponse());

  Map<String, dynamic>? lastLoginPayloads;
  Map<String, dynamic>? lastRegisterPayloads;
  Map<String, dynamic>? lastForgotPasswordPayloads;

  String get path4AppleLogin => '/auth/apple/';

  String get path4ForgetPassword => '/auth/forgot-password/';

  String get path4GoogleLogin => '/auth/google/';

  String get path4Login => '/auth/login/';

  String get path4Register => '/auth/register/';

  @override
  Future<EitherResponseOrException<AuthSession>> appleLogin({
    CancelToken? cancelToken,
  }) async {
    return appleLoginResult;
  }

  @override
  Future<EitherResponseOrException<ForgotPasswordResponse>> forgetPassword({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) async {
    lastForgotPasswordPayloads = payloads;
    return forgotPasswordResult;
  }

  @override
  Future<EitherResponseOrException<AuthSession>> googleLogin({
    List<String> scopes = const ['email'],
    CancelToken? cancelToken,
  }) async {
    return googleLoginResult;
  }

  @override
  Future<EitherResponseOrException<AuthSession>> login({
    required Map<String, dynamic> payloads,
    CancelToken? cancelToken,
  }) async {
    lastLoginPayloads = payloads;
    return loginResult;
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
