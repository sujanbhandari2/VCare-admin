import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_to_local_profile_mapper.dart';

void main() {
  group('localProfileFromAuthMe', () {
    test('maps display name, contact fields, dob, and profile preview link', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'sujan@vitafyhealth.com',
          phoneNumber: '+15551234567',
          dateOfBirth: '1990-01-15T00:00:00.000Z',
          profilePreviewLink: 'https://cdn.example.com/jane-preview.jpg',
          profileImage: 'https://cdn.example.com/jane.jpg',
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.fullName, 'Jane Doe');
      expect(profile.email, 'sujan@vitafyhealth.com');
      expect(profile.phone, '+15551234567');
      expect(profile.dob, '01/15/1990');
      expect(profile.photoUrl, 'https://cdn.example.com/jane-preview.jpg');
    });

    test('falls back to agent profile preview link when user has no photo', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Omnis',
          lastName: 'Porro',
        ),
        agentProfile: AuthMeAgentProfile(
          profilePreviewLink: 'https://cdn.example.com/agent-preview.jpg',
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.photoUrl, 'https://cdn.example.com/agent-preview.jpg');
    });

    test('returns null photo url when no preview links are available', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Omnis',
          lastName: 'Porro',
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.photoUrl, isNull);
    });

    test('falls back to Member when display name is empty', () {
      const authMe = AuthMe(user: AuthMeUser());

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.fullName, 'Member');
      expect(profile.email, '');
      expect(profile.phone, '');
    });
    test('maps agent profile referral link into local profile', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Omnis',
          lastName: 'Porro',
          email: 'agent@gmail.com',
        ),
        agentProfile: AuthMeAgentProfile(
          referralLink: 'https://localhost:8080/refer/AGT-22581',
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.referralLink, 'https://localhost:8080/refer/AGT-22581');
    });
  });

  group('AuthMe.referralLink', () {
    test('returns agent profile referral link', () {
      const authMe = AuthMe(
        user: AuthMeUser(email: 'agent@gmail.com'),
        agentProfile: AuthMeAgentProfile(
          referralLink: 'https://localhost:8080/refer/AGT-22581',
        ),
      );

      expect(authMe.referralLink, 'https://localhost:8080/refer/AGT-22581');
    });
  });

  group('AuthMe.profilePhotoUrl', () {
    test('prefers user preview link over agent preview and profile image', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          profilePreviewLink: 'https://cdn.example.com/user-preview.jpg',
          profileImage: 'https://cdn.example.com/user.jpg',
        ),
        agentProfile: AuthMeAgentProfile(
          profilePreviewLink: 'https://cdn.example.com/agent-preview.jpg',
        ),
      );

      expect(authMe.profilePhotoUrl, 'https://cdn.example.com/user-preview.jpg');
    });
  });
}
