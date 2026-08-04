import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_identifier_normalizer.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';

void main() {
  group('AuthIdentifierNormalizer', () {
    test('phone strips non-digits when no country provided', () {
      expect(
        AuthIdentifierNormalizer.normalize(
          method: LoginFlowMethod.phone,
          raw: '(555) 123-4567',
        ),
        '5551234567',
      );
    });

    test('phone includes country code for USA', () {
      expect(
        AuthIdentifierNormalizer.normalize(
          method: LoginFlowMethod.phone,
          raw: '(555) 123-4567',
          phoneCountry: AuthPhoneCountry.usa,
        ),
        '15551234567',
      );
    });

    test('email trims and lowercases', () {
      expect(
        AuthIdentifierNormalizer.normalize(
          method: LoginFlowMethod.email,
          raw: '  User@Example.com ',
        ),
        'user@example.com',
      );
    });
  });
}
