import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_identifier_normalizer.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';

void main() {
  group('AuthIdentifierNormalizer', () {
    test('phone strips non-digits', () {
      expect(
        AuthIdentifierNormalizer.normalize(
          method: LoginFlowMethod.phone,
          raw: '(555) 123-4567',
        ),
        '5551234567',
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
