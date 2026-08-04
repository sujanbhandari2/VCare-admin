import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/data/mappers/auth_me_update_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';

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

    test('maps address with null line2 when omitted', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        address: const ProfileAddress(
          line1: '123 Market St',
          city: 'San Francisco',
          state: 'CA',
          postalCode: '94103',
          country: 'United States',
        ),
      );

      expect(payload['address'], {
        'addressLine1': '123 Market St',
        'addressLine2': null,
        'city': 'San Francisco',
        'state': 'CA',
        'postalCode': '94103',
      });
    });

    test('includes bio when includeBio is true', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        bio: '  Helping families find coverage.  ',
        includeBio: true,
      );

      expect(payload['bio'], 'Helping families find coverage.');
    });

    test('sends null bio when includeBio is true and bio is empty', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        bio: '   ',
        includeBio: true,
      );

      expect(payload.containsKey('bio'), isTrue);
      expect(payload['bio'], isNull);
    });

    test('omits bio when includeBio is false', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        bio: 'Should not be sent',
      );

      expect(payload.containsKey('bio'), isFalse);
    });

    test('includes allowTextNotification when provided', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        allowTextNotification: true,
      );

      expect(payload['allowTextNotification'], isTrue);
    });

    test('includes primary location and nulls blanks when flagged', () {
      final withValues = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        primaryCity: ' Tampa ',
        primaryState: ' FL ',
        includePrimaryLocation: true,
      );
      expect(withValues['primaryCity'], 'Tampa');
      expect(withValues['primaryState'], 'FL');

      final cleared = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        primaryCity: '',
        primaryState: '',
        includePrimaryLocation: true,
      );
      expect(cleared.containsKey('primaryCity'), isTrue);
      expect(cleared['primaryCity'], isNull);
      expect(cleared['primaryState'], isNull);
    });

    test('sends empty address object when clearAddress is true', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        clearAddress: true,
      );

      expect(payload['address'], {
        'addressLine1': '',
        'addressLine2': null,
        'city': '',
        'state': '',
        'postalCode': '',
      });
    });

    test('sends null middleName when empty', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        middleName: '  ',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
      );

      expect(payload.containsKey('middleName'), isTrue);
      expect(payload['middleName'], isNull);
    });

    test('includes gender when provided', () {
      final payload = toUpdateMePayload(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '+15551234567',
        dateOfBirth: '1990-05-14',
        gender: 'MALE',
      );

      expect(payload['gender'], 'MALE');
    });
  });

  group('buildProfileUpdateBody', () {
    const initial = ProfileEditFormData(
      firstName: 'Jane',
      middleName: '',
      lastName: 'Doe',
      email: 'jane@example.com',
      phone: '5551234567',
      dob: '1990-05-14',
      gender: 'Male',
      allowTextNotification: false,
      bio: '',
      primaryCity: '',
      primaryState: '',
    );

    test('returns empty body when nothing changed', () {
      final body = buildProfileUpdateBody(
        form: initial,
        initial: initial,
        phoneForApi: '+15551234567',
        initialPhoneForApi: '+15551234567',
      );

      expect(body, isEmpty);
    });

    test('includes only changed fields', () {
      final body = buildProfileUpdateBody(
        form: initial.copyWith(firstName: 'Janet', bio: 'Hello'),
        initial: initial,
        phoneForApi: '+15551234567',
        initialPhoneForApi: '+15551234567',
      );

      expect(body.keys, unorderedEquals(['firstName', 'bio']));
      expect(body['firstName'], 'Janet');
      expect(body['bio'], 'Hello');
    });

    test('maps gender UI change to API enum', () {
      final body = buildProfileUpdateBody(
        form: initial.copyWith(gender: 'Female'),
        initial: initial,
        phoneForApi: '+15551234567',
        initialPhoneForApi: '+15551234567',
      );

      expect(body['gender'], 'FEMALE');
    });

    test('clears address when fields emptied after having address', () {
      const withAddress = ProfileEditFormData(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '5551234567',
        dob: '1990-05-14',
        line1: '123 Market St',
        city: 'San Francisco',
        state: 'CA',
        postalCode: '94103',
      );

      final body = buildProfileUpdateBody(
        form: withAddress.copyWith(
          line1: '',
          city: '',
          state: '',
          postalCode: '',
        ),
        initial: withAddress,
        phoneForApi: '+15551234567',
        initialPhoneForApi: '+15551234567',
      );

      expect(body['address'], {
        'addressLine1': '',
        'addressLine2': null,
        'city': '',
        'state': '',
        'postalCode': '',
      });
    });

    test('includes profileId when flagged', () {
      final body = buildProfileUpdateBody(
        form: initial,
        initial: initial,
        phoneForApi: '+15551234567',
        initialPhoneForApi: '+15551234567',
        profileId: 'file-id',
        includeProfileId: true,
      );

      expect(body['profileId'], 'file-id');
    });

    test('nulls primary location when cleared', () {
      const withPrimary = ProfileEditFormData(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane@example.com',
        phone: '5551234567',
        dob: '1990-05-14',
        primaryCity: 'Tampa',
        primaryState: 'FL',
      );

      final body = buildProfileUpdateBody(
        form: withPrimary.copyWith(primaryCity: '', primaryState: ''),
        initial: withPrimary,
        phoneForApi: '+15551234567',
        initialPhoneForApi: '+15551234567',
      );

      expect(body['primaryCity'], isNull);
      expect(body['primaryState'], isNull);
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
