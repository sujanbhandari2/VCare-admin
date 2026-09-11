import 'package:dio/dio.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_challenge.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';

abstract class BiometricLoginRepository {
  /// Reads the single local biometric credential.
  ///
  /// When [accountId] is provided (settings), enrollment is reported only if
  /// the stored credential belongs to that account. When omitted (sign-in),
  /// any valid local credential is treated as available for biometric login.
  Future<EitherResponseOrException<BiometricLoginStatus>> fetchStatus({
    String? accountId,
  });

  Future<EitherResponseOrException<BiometricLoginStatus>> enroll({
    required String accessToken,
    required String accountId,
    String? accountEmail,
    String? userType,
    String? deviceName,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<BiometricChallenge>> challenge({
    String? userType,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<AdminAuthSession>> loginWithChallenge({
    required BiometricChallenge challenge,
    String? userType,
    CancelToken? cancelToken,
  });

  /// Calls `DELETE /auth/biometric/current`, then clears the native key and
  /// local credential. On API failure the local credential is retained.
  Future<EitherResponseOrException<void>> revoke({
    required String accessToken,
    String? userType,
    CancelToken? cancelToken,
  });
}
