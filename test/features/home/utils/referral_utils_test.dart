import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/home/utils/referral_utils.dart';

void main() {
  group('resolveReferralUrl', () {
    test('returns server referral link when provided', () {
      expect(
        resolveReferralUrl(
          email: 'agent@gmail.com',
          referralLink: 'https://localhost:8080/refer/AGT-22581',
        ),
        'https://localhost:8080/refer/AGT-22581',
      );
    });

    test('falls back to email slug when referral link is missing', () {
      expect(
        resolveReferralUrl(email: 'agent@gmail.com'),
        'https://vcare.app/refer/agent',
      );
    });
  });
}
