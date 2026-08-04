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

  group('validateAgentCode', () {
    test('rejects short codes', () {
      expect(validateAgentCode('ab'), 'Code must be at least 3 characters');
    });

    test('rejects long codes', () {
      expect(
        validateAgentCode('a' * 65),
        'Code must be at most 64 characters',
      );
    });

    test('rejects invalid characters', () {
      expect(
        validateAgentCode('bad_code'),
        'Use only letters, numbers, and hyphens',
      );
    });

    test('accepts valid codes', () {
      expect(validateAgentCode('AGT-22581'), isNull);
      expect(validateAgentCode('abc'), isNull);
    });
  });

  group('normalizeAgentCode', () {
    test('strips whitespace and lowercases', () {
      expect(normalizeAgentCode('  My-Code  '), 'my-code');
      expect(normalizeAgentCode('A B C'), 'abc');
    });
  });

  group('splitReferralUrl', () {
    test('prefers agentCode over path segment', () {
      final parts = splitReferralUrl(
        'https://vcare.app/refer/path-code',
        agentCode: 'agent-code',
      );
      expect(parts.prefix, 'https://vcare.app/refer/');
      expect(parts.code, 'agent-code');
    });

    test('uses last path segment when agentCode is absent', () {
      final parts = splitReferralUrl('https://vcare.app/refer/path-code');
      expect(parts.prefix, 'https://vcare.app/refer/');
      expect(parts.code, 'path-code');
    });
  });

  group('replaceReferralCode', () {
    test('rewrites the last path segment', () {
      expect(
        replaceReferralCode(
          'https://vcare.app/refer/old-code',
          'new-code',
        ),
        'https://vcare.app/refer/new-code',
      );
    });

    test('returns null for empty link', () {
      expect(replaceReferralCode(null, 'new-code'), isNull);
      expect(replaceReferralCode('  ', 'new-code'), isNull);
    });
  });
}
