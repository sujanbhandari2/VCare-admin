import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';

void main() {
  group('AuthPhoneFormatter', () {
    test('toE164 prefixes +1 for 10-digit US numbers', () {
      expect(AuthPhoneFormatter.toE164('5551234567'), '+15551234567');
    });

    test('toE164 keeps 11-digit numbers starting with 1', () {
      expect(AuthPhoneFormatter.toE164('15551234567'), '+15551234567');
    });

    test('toE164 returns empty string for empty input', () {
      expect(AuthPhoneFormatter.toE164(''), '');
    });
  });
}
