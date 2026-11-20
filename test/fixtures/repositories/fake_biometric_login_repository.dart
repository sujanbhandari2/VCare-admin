import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_challenge.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';
import 'package:vcare_admin/features/biometric_login/domain/repositories/biometric_login_repository.dart';

class FakeBiometricLoginRepository implements BiometricLoginRepository {
  BiometricLoginStatus status = BiometricLoginStatus.disabled;

  @override
  Future<EitherResponseOrException<BiometricLoginStatus>> fetchStatus({
    String? accountId,
  }) async {
    return Success(status);
  }

  @override
  Future<EitherResponseOrException<BiometricLoginStatus>> enroll({
    required String accessToken,
    required String accountId,
    String? accountEmail,
    String? userType,
    String? deviceName,
    CancelToken? cancelToken,
  }) async {
    status = BiometricLoginStatus(
      isEnrolled: true,
      accountId: accountId,
      accountEmail: accountEmail,
    );
    return Success(status);
  }

  @override
  Future<EitherResponseOrException<BiometricChallenge>> challenge({
    String? userType,
    CancelToken? cancelToken,
  }) async {
    return const Success(
      BiometricChallenge(
        challengeToken: 'challenge',
        nonce: 'nonce',
      ),
    );
  }

  @override
  Future<EitherResponseOrException<void>> authenticateForLogin({
    String? userType,
    String? preferredBiometric,
    String? reason,
  }) async {
    return const Success(null);
  }

  @override
  Future<void> cancelLoginAuthentication() async {}

  @override
  Future<void> clearLocalCredential() async {
    status = BiometricLoginStatus.disabled;
  }

  @override
  Future<EitherResponseOrException<AdminAuthSession>> loginWithChallenge({
    required BiometricChallenge challenge,
    String? userType,
    CancelToken? cancelToken,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<EitherResponseOrException<void>> revoke({
    required String accessToken,
    String? userType,
    CancelToken? cancelToken,
  }) async {
    status = BiometricLoginStatus.disabled;
    return const Success(null);
  }
}
