import 'package:flutter_test/flutter_test.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/features/auth/domain/auth_error_message.dart';

void main() {
  group('resolveBiometricLoginAuthErrorMessage', () {
    test('returns user access revoked message', () {
      final error = HttpException(
        message: AuthErrorMessage.userAccessRevoked,
      );

      expect(
        resolveBiometricLoginAuthErrorMessage(error),
        AuthErrorMessage.userAccessRevoked,
      );
      expect(isBiometricLoginDisablingAuthError(error), isTrue);
    });

    test('returns biometric not enrolled message', () {
      final error = HttpException(
        message: AuthErrorMessage.biometricLoginNotEnrolled,
      );

      expect(
        resolveBiometricLoginAuthErrorMessage(error),
        AuthErrorMessage.biometricLoginNotEnrolled,
      );
    });

    test('returns biometric revoked message', () {
      final error = HttpException(
        message: AuthErrorMessage.biometricLoginRevoked,
      );

      expect(
        resolveBiometricLoginAuthErrorMessage(error),
        AuthErrorMessage.biometricLoginRevoked,
      );
    });

    test('matches message nested in response data', () {
      final error = HttpException(
        message: 'Request failed',
        responseData: {
          'message': AuthErrorMessage.biometricLoginRevoked,
        },
      );

      expect(
        resolveBiometricLoginAuthErrorMessage(error),
        AuthErrorMessage.biometricLoginRevoked,
      );
    });

    test('returns null for unrelated errors', () {
      final error = HttpException(message: 'Invalid credentials');

      expect(resolveBiometricLoginAuthErrorMessage(error), isNull);
      expect(isBiometricLoginDisablingAuthError(error), isFalse);
    });
  });
}
