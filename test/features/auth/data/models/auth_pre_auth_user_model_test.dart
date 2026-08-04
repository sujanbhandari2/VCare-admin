import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/data/mappers/auth_mappers.dart';
import 'package:vcare_admin/features/auth/data/models/auth_pre_auth_user_model.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';

void main() {
  group('AuthPreAuthUserModel', () {
    test('fromJson maps all fields when present', () {
      final model = AuthPreAuthUserModel.fromJson({
        'firstName': 'Jane',
        'middleName': 'Q',
        'lastName': 'Doe',
        'dob': '1990-01-15',
        'zipCode': '12345',
        'email': 'jane@example.com',
        'phone': '+15551234567',
        'gender': 'FEMALE',
        'primaryCity': 'New Orleans',
        'primaryState': 'Louisiana',
      });

      final entity = model.toEntity();

      expect(entity.firstName, 'Jane');
      expect(entity.middleName, 'Q');
      expect(entity.lastName, 'Doe');
      expect(entity.dob, '1990-01-15');
      expect(entity.zipCode, '12345');
      expect(entity.email, 'jane@example.com');
      expect(entity.phone, '+15551234567');
      expect(entity.gender, 'FEMALE');
      expect(entity.primaryCity, 'New Orleans');
      expect(entity.primaryState, 'Louisiana');
    });

    test('fromJson ignores missing and empty fields', () {
      final model = AuthPreAuthUserModel.fromJson({
        'firstName': '  ',
        'lastName': null,
        'email': 'user@example.com',
        'gender': '',
        'primaryCity': '  ',
      });

      final entity = model.toEntity();

      expect(entity.firstName, isNull);
      expect(entity.lastName, isNull);
      expect(entity.dob, isNull);
      expect(entity.zipCode, isNull);
      expect(entity.email, 'user@example.com');
      expect(entity.phone, isNull);
      expect(entity.gender, isNull);
      expect(entity.primaryCity, isNull);
      expect(entity.primaryState, isNull);
    });
  });

  group('AuthPhoneFormatter.toDisplayDigits', () {
    test('strips +1 country code for 11-digit numbers', () {
      expect(
        AuthPhoneFormatter.toDisplayDigits('+15551234567'),
        '5551234567',
      );
    });

    test('returns 10-digit numbers unchanged', () {
      expect(AuthPhoneFormatter.toDisplayDigits('5551234567'), '5551234567');
    });

    test('returns empty string for empty input', () {
      expect(AuthPhoneFormatter.toDisplayDigits(''), '');
    });
  });
}
