import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';

void main() {
  group('AuthPhoneFormatter', () {
    group('toApiDigits', () {
      test('combines US dial code and national digits without plus', () {
        expect(
          AuthPhoneFormatter.toApiDigits('1', '5551234567'),
          '15551234567',
        );
      });

      test('combines Nepal dial code and national digits', () {
        expect(
          AuthPhoneFormatter.toApiDigits('977', '9841234567'),
          '9779841234567',
        );
      });

      test('returns empty string for empty national digits', () {
        expect(AuthPhoneFormatter.toApiDigits('1', ''), '');
      });
    });

    group('toDisplayDigits', () {
      test('strips +1 country code for 11-digit numbers', () {
        expect(
          AuthPhoneFormatter.toDisplayDigits('15551234567'),
          '5551234567',
        );
      });

      test('strips 977 country code for Nepal numbers', () {
        expect(
          AuthPhoneFormatter.toDisplayDigits('9779841234567'),
          '9841234567',
        );
      });

      test('returns 10-digit national number as-is', () {
        expect(AuthPhoneFormatter.toDisplayDigits('5551234567'), '5551234567');
      });

      test('returns empty string for empty input', () {
        expect(AuthPhoneFormatter.toDisplayDigits(''), '');
      });
    });

    group('detectCountry', () {
      test('detects Nepal from 977 prefix', () {
        expect(
          AuthPhoneFormatter.detectCountry('9779841234567'),
          AuthPhoneCountry.nepal,
        );
      });

      test('detects USA from 11-digit number starting with 1', () {
        expect(
          AuthPhoneFormatter.detectCountry('15551234567'),
          AuthPhoneCountry.usa,
        );
      });

      test('returns fallback for ambiguous input', () {
        expect(
          AuthPhoneFormatter.detectCountry(
            '5551234567',
            fallback: AuthPhoneCountry.canada,
          ),
          AuthPhoneCountry.canada,
        );
      });
    });

    group('toE164', () {
      test('prefixes +1 for 10-digit US numbers', () {
        expect(AuthPhoneFormatter.toE164('5551234567'), '+15551234567');
      });
    });
  });
}
