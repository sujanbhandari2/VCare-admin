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

    group('formatNationalDisplay', () {
      test('formats US numbers as (XXX) XXX-XXXX', () {
        expect(
          AuthPhoneFormatter.formatNationalDisplay(
            '5551234567',
            AuthPhoneCountry.usa,
          ),
          '(555) 123-4567',
        );
      });

      test('formats partial US numbers while typing', () {
        expect(
          AuthPhoneFormatter.formatNationalDisplay(
            '555',
            AuthPhoneCountry.usa,
          ),
          '(555',
        );
        expect(
          AuthPhoneFormatter.formatNationalDisplay(
            '555123',
            AuthPhoneCountry.usa,
          ),
          '(555) 123',
        );
      });

      test('formats Nepal numbers as XXX XXXX XXX', () {
        expect(
          AuthPhoneFormatter.formatNationalDisplay(
            '9804332283',
            AuthPhoneCountry.nepal,
          ),
          '980 4332 283',
        );
      });

      test('formats partial Nepal numbers while typing', () {
        expect(
          AuthPhoneFormatter.formatNationalDisplay(
            '980',
            AuthPhoneCountry.nepal,
          ),
          '980',
        );
        expect(
          AuthPhoneFormatter.formatNationalDisplay(
            '9804332',
            AuthPhoneCountry.nepal,
          ),
          '980 4332',
        );
      });

      test('returns empty string for empty input', () {
        expect(
          AuthPhoneFormatter.formatNationalDisplay('', AuthPhoneCountry.usa),
          '',
        );
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

    group('formatInternationalDisplay', () {
      test('formats US numbers with +1 prefix', () {
        expect(
          AuthPhoneFormatter.formatInternationalDisplay('+15551234567'),
          '+1 (555) 123-4567',
        );
      });

      test('formats Nepal numbers with +977 prefix', () {
        expect(
          AuthPhoneFormatter.formatInternationalDisplay('9779804332283'),
          '+977 980 4332 283',
        );
      });

      test('returns empty string for empty input', () {
        expect(AuthPhoneFormatter.formatInternationalDisplay(''), '');
      });
    });

    group('toE164', () {
      test('prefixes +1 for 10-digit US numbers', () {
        expect(AuthPhoneFormatter.toE164('5551234567'), '+15551234567');
      });
    });
  });
}
