import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

void main() {
  group('parseProfileDob', () {
    test('parses US date format', () {
      final parsed = parseProfileDob('07/01/1995');

      expect(parsed, isNotNull);
      expect(parsed!.year, 1995);
      expect(parsed.month, 7);
      expect(parsed.day, 1);
    });

    test('parses ISO date format', () {
      final parsed = parseProfileDob('1990-05-14');

      expect(parsed, isNotNull);
      expect(parsed!.year, 1990);
      expect(parsed.month, 5);
      expect(parsed.day, 14);
    });

    test('parses ISO timestamp', () {
      final parsed = parseProfileDob('1990-01-15T00:00:00.000Z');

      expect(parsed, isNotNull);
      expect(parsed!.year, 1990);
      expect(parsed.month, 1);
      expect(parsed.day, 15);
    });

    test('returns null for empty or invalid input', () {
      expect(parseProfileDob(null), isNull);
      expect(parseProfileDob(''), isNull);
      expect(parseProfileDob('not-a-date'), isNull);
    });
  });

  group('formatProfileDob', () {
    test('formats ISO input to US date', () {
      expect(formatProfileDob('1990-01-15T00:00:00.000Z'), '01/15/1990');
    });

    test('keeps already formatted US date', () {
      expect(formatProfileDob('07/01/1995'), '07/01/1995');
    });
  });

  group('ageFromDob', () {
    test('calculates age from US date format', () {
      final now = DateTime.now();
      final dob = '${now.month.toString().padLeft(2, '0')}/'
          '${now.day.toString().padLeft(2, '0')}/'
          '${now.year - 30}';

      expect(ageFromDob(dob), 30);
    });
  });

  group('profile gender mapping', () {
    test('maps API values to UI labels', () {
      expect(mapProfileGenderApiToUi('MALE'), 'Male');
      expect(mapProfileGenderApiToUi('FEMALE'), 'Female');
      expect(mapProfileGenderApiToUi('OTHER'), 'Others');
      expect(mapProfileGenderApiToUi(null), '');
      expect(mapProfileGenderApiToUi(''), '');
    });

    test('maps UI labels to API values', () {
      expect(mapProfileGenderUiToApi('Male'), 'MALE');
      expect(mapProfileGenderUiToApi('Female'), 'FEMALE');
      expect(mapProfileGenderUiToApi('Others'), 'OTHER');
      expect(mapProfileGenderUiToApi(''), isNull);
      expect(mapProfileGenderUiToApi(null), isNull);
    });
  });
}
