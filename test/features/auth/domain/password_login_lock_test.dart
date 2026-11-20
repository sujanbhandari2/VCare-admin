import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/features/auth/domain/password_login_lock.dart';

void main() {
  group('resolvePasswordLoginErrorMessage', () {
    test('formats remaining attempts for email login', () {
      final error = HttpException(
        message: 'Invalid credentials',
        statusCode: 401,
        responseData: {'passwordTriesLeft': 3},
      );

      expect(
        resolvePasswordLoginErrorMessage(error),
        'Incorrect email or password. You have 3 login attempts remaining.',
      );
    });

    test('uses singular attempt label when one try remains', () {
      final error = HttpException(
        message: 'Invalid credentials',
        statusCode: 401,
        responseData: {'passwordTriesLeft': 1},
      );

      expect(
        resolvePasswordLoginErrorMessage(error),
        'Incorrect email or password. You have 1 login attempt remaining.',
      );
    });

    test('uses email fallback for invalid credentials', () {
      final error = HttpException(
        message: 'Invalid credentials',
        statusCode: 401,
      );

      expect(
        resolvePasswordLoginErrorMessage(
          error,
          wrongPasswordFallbackMessage: wrongPasswordFallback,
        ),
        wrongPasswordFallback,
      );
    });

    test('returns empty message for account lock', () {
      final error = HttpException(
        message: 'Blocked',
        statusCode: 403,
        responseData: {
          'code': AuthPasswordLoginErrorCode.accountPasswordLocked,
        },
      );

      expect(resolvePasswordLoginErrorMessage(error), '');
    });

    test('reads passwordTriesLeft from nested data payload', () {
      final error = HttpException(
        message: 'Invalid credentials',
        statusCode: 401,
        responseData: {
          'data': {'passwordTriesLeft': 2},
        },
      );

      expect(
        resolvePasswordLoginErrorMessage(error),
        'Incorrect email or password. You have 2 login attempts remaining.',
      );
    });
  });

  group('isAccountPasswordLockedError', () {
    test('detects lock code', () {
      final error = HttpException(
        message: 'Blocked',
        statusCode: 403,
        responseData: {
          'code': AuthPasswordLoginErrorCode.accountPasswordLocked,
        },
      );

      expect(isAccountPasswordLockedError(error), isTrue);
    });

    test('returns false for unrelated errors', () {
      final error = HttpException(
        message: 'Invalid credentials',
        statusCode: 401,
      );

      expect(isAccountPasswordLockedError(error), isFalse);
    });
  });

  group('resolveAccountPasswordLockSupportEmail', () {
    test('uses API supportEmail when present', () {
      final error = HttpException(
        message: 'Blocked',
        statusCode: 403,
        responseData: {
          'code': AuthPasswordLoginErrorCode.accountPasswordLocked,
          'supportEmail': 'help@example.com',
        },
      );

      expect(
        resolveAccountPasswordLockSupportEmail(error),
        'help@example.com',
      );
    });

    test('falls back to default support email', () {
      final error = HttpException(
        message: 'Blocked',
        statusCode: 403,
        responseData: {
          'code': AuthPasswordLoginErrorCode.accountPasswordLocked,
        },
      );

      expect(
        resolveAccountPasswordLockSupportEmail(error),
        loginPasswordLockSupportEmail,
      );
    });
  });
}
