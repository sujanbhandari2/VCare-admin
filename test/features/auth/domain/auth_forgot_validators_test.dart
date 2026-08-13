import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_forgot_validators.dart';

void main() {
  group('AuthPasswordValidator', () {
    test('accepts strong password', () {
      expect(
        AuthPasswordValidator.validateStrength('Password1!'),
        isNull,
      );
    });

    test('rejects short password', () {
      expect(
        AuthPasswordValidator.validateStrength('Pw1!'),
        'Password must be at least 8 characters.',
      );
    });

    test('rejects password without special character', () {
      expect(
        AuthPasswordValidator.validateStrength('Password1'),
        'Password must include a special character.',
      );
    });
  });

  group('AuthForgotDobValidator', () {
    test('accepts valid ISO date', () {
      expect(AuthForgotDobValidator.validate('1990-01-15'), isNull);
    });

    test('rejects empty dob', () {
      expect(
        AuthForgotDobValidator.validate(''),
        'Please enter your date of birth.',
      );
    });

    test('rejects invalid date', () {
      expect(
        AuthForgotDobValidator.validate('not-a-date'),
        'Enter a valid date of birth.',
      );
    });
  });

  group('AuthForgotZipValidator', () {
    test('accepts 5-digit zip', () {
      expect(AuthForgotZipValidator.validate('12345'), isNull);
    });

    test('accepts zip+4 format', () {
      expect(AuthForgotZipValidator.validate('12345-6789'), isNull);
    });

    test('rejects invalid zip', () {
      expect(
        AuthForgotZipValidator.validate('1234'),
        'Enter a valid 5-digit ZIP code.',
      );
    });
  });
}
