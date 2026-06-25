import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_to_local_profile_mapper.dart';

void main() {
  group('localProfileFromAuthMeUser', () {
    test('maps display name, contact fields, dob, and photo url', () {
      const user = AuthMeUser(
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'sujan@vitafyhealth.com',
        phoneNumber: '+15551234567',
        dateOfBirth: '1990-01-15T00:00:00.000Z',
        profileImage: 'https://cdn.example.com/jane.jpg',
      );

      final profile = localProfileFromAuthMeUser(user);

      expect(profile.fullName, 'Jane Doe');
      expect(profile.email, 'sujan@vitafyhealth.com');
      expect(profile.phone, '+15551234567');
      expect(profile.dob, '01/15/1990');
      expect(profile.photoUrl, 'https://cdn.example.com/jane.jpg');
    });

    test('falls back to Member when display name is empty', () {
      const user = AuthMeUser();

      final profile = localProfileFromAuthMeUser(user);

      expect(profile.fullName, 'Member');
      expect(profile.email, '');
      expect(profile.phone, '');
    });
  });
}
