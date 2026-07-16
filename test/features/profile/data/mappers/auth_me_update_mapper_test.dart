import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/data/mappers/auth_me_update_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

void main() {
  group('toUpdateMePayload', () {
    test('includes profileId when provided', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        profileId: 'f71ebd0f-8d75-4a09-9a72-13906ae2dfc8',
      );

      expect(payload['profileId'], 'f71ebd0f-8d75-4a09-9a72-13906ae2dfc8');
      expect(payload.containsKey('profileImage'), isFalse);
    });

    test('omits profileId when missing', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
      );

      expect(payload.containsKey('profileId'), isFalse);
    });

    test('maps address fields', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        address: const ProfileAddress(
          line1: '123 Market St',
          line2: 'Apt 4B',
          city: 'San Francisco',
          state: 'CA',
          postalCode: '94103',
          country: 'United States',
        ),
      );

      expect(payload['address'], {
        'addressLine1': '123 Market St',
        'addressLine2': 'Apt 4B',
        'city': 'San Francisco',
        'state': 'CA',
        'postalCode': '94103',
      });
    });
  });

  group('splitFullName', () {
    test('splits three-part names', () {
      final parts = splitFullName('Jane Marie Doe');
      expect(parts.firstName, 'Jane');
      expect(parts.middleName, 'Marie');
      expect(parts.lastName, 'Doe');
    });

    test('splits two-part names', () {
      final parts = splitFullName('Jane Doe');
      expect(parts.firstName, 'Jane');
      expect(parts.middleName, isNull);
      expect(parts.lastName, 'Doe');
    });
  });
}
