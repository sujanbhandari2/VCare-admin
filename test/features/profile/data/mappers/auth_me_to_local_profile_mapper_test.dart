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
      expect(profile.dob, 'Jan 15, 1990');
      expect(profile.photoUrl, 'https://cdn.example.com/jane-preview.jpg');
      expect(
        profile.photoCacheKey,
        'profile-photo:https://cdn.example.com/jane.jpg',
      );
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
          agentCode: 'AGT-22581',
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.referralLink, 'https://localhost:8080/refer/AGT-22581');
      expect(profile.agentCode, 'AGT-22581');
    });

    test('maps agency group from agent profile for referral card agency section', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Agent',
          lastName: 'User',
          email: 'agent@gmail.com',
        ),
        agentProfile: AuthMeAgentProfile(
          agentCode: 'AGT-22581',
          agencyGroup: AuthMeAgencyGroup(
            id: 'group-1',
            name: 'Acme Insurance',
          ),
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.agencyGroupId, 'group-1');
      expect(profile.agencyName, 'Acme Insurance');
      expect(profile.hasAgencyGroup, isTrue);
      expect(profile.agentCode, 'AGT-22581');
    });

    test('maps agency group from user agencyGroupName for referral card', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Sujan',
          lastName: 'bhandari',
          email: 'sujan+222@vitafyhealth.com',
          agencyGroupId: 'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
          agencyGroupName: 'Agency grouup',
        ),
        agentProfile: AuthMeAgentProfile(
          agentCode: 'AGT-00002',
          agencyGroup: AuthMeAgencyGroup(
            id: 'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
          ),
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(
        profile.agencyGroupId,
        'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
      );
      expect(profile.agencyName, 'Agency grouup');
      expect(profile.hasAgencyGroup, isTrue);
    });

    test('prefers user agency group fields over nested agent agencyGroup', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Sujan',
          lastName: 'bhandari',
          agencyGroupId: 'user-group-id',
          agencyGroupName: 'User Agency Name',
        ),
        agentProfile: AuthMeAgentProfile(
          agencyGroup: AuthMeAgencyGroup(
            id: 'agent-group-id',
            name: 'Agent Agency Name',
          ),
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.agencyGroupId, 'user-group-id');
      expect(profile.agencyName, 'User Agency Name');
    });

    test('leaves agency group empty when agent profile has null agencyGroup', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Sujan',
          lastName: 'Bhandari',
          email: 'sujan+111@vitafyhealth.com',
          currentTenant: AuthMeTenant(
            id: 'tenant-1',
            slug: 'default',
            name: 'Default',
          ),
        ),
        agentProfile: AuthMeAgentProfile(
          agentCode: 'AGT-52592',
          agencyGroup: null,
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.agencyGroupId, isNull);
      expect(profile.agencyName, isNull);
      expect(profile.hasAgencyGroup, isFalse);
    });

    test('maps agent profile address and prefers agent contact fields', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          firstName: 'Sujan',
          lastName: 'bhandari',
          email: 'sujan+222@vitafyhealth.com',
          phoneNumber: '+13434343434',
          dateOfBirth: '1995-07-01T00:00:00.000Z',
          gender: 'MALE',
          profilePreviewLink: 'https://cdn.example.com/user-preview.jpg',
        ),
        agentProfile: AuthMeAgentProfile(
          firstName: 'Sujan',
          middleName: 'K',
          lastName: 'bhandari',
          email: 'sujan+222@vitafyhealth.com',
          phoneNumber: '+13434343434',
          dateOfBirth: '1995-07-01T00:00:00.000Z',
          profilePreviewLink: 'https://cdn.example.com/agent-preview.jpg',
          bio: 'Licensed agent helping families navigate coverage.',
          allowTextNotification: true,
          primaryCity: 'Tampa',
          primaryState: 'FL',
          address: AuthMeAddress(
            addressLine1: 'Autem eos iste rerum',
            addressLine2: 'Et placeat mollitia',
            city: 'Aut saepe ipsum do c',
            state: 'Arkansas',
            postalCode: '97733',
          ),
        ),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.firstName, 'Sujan');
      expect(profile.middleName, 'K');
      expect(profile.lastName, 'bhandari');
      expect(profile.fullName, 'Sujan K bhandari');
      expect(profile.email, 'sujan+222@vitafyhealth.com');
      expect(profile.phone, '+13434343434');
      expect(profile.dob, 'Jul 1, 1995');
      expect(profile.gender, 'Male');
      expect(profile.photoUrl, 'https://cdn.example.com/user-preview.jpg');
      expect(
        profile.bio,
        'Licensed agent helping families navigate coverage.',
      );
      expect(profile.allowTextNotification, isTrue);
      expect(profile.primaryCity, 'Tampa');
      expect(profile.primaryState, 'FL');
      expect(profile.address?.line1, 'Autem eos iste rerum');
      expect(profile.address?.line2, 'Et placeat mollitia');
      expect(profile.address?.city, 'Aut saepe ipsum do c');
      expect(profile.address?.state, 'Arkansas');
      expect(profile.address?.postalCode, '97733');
      expect(profile.address?.country, 'United States');
    });

    test('maps OTHER gender to Others UI label', () {
      const authMe = AuthMe(
        user: AuthMeUser(gender: 'OTHER'),
      );

      final profile = localProfileFromAuthMe(authMe);

      expect(profile.gender, 'Others');
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

    test('builds stable cache key from profile image storage path', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          id: 'user-1',
          profilePreviewLink:
              'https://cdn.example.com/user-preview.jpg?token=one',
          profileImage: 'users/user-1/profile.jpg',
        ),
      );

      expect(
        authMe.profilePhotoCacheKey,
        'profile-photo:users/user-1/profile.jpg',
      );
    });

    test('builds stable cache key from agent profile file storage path', () {
      const authMe = AuthMe(
        user: AuthMeUser(
          id: 'user-1',
          profilePreviewLink:
              'https://cdn.example.com/user-preview.jpg?token=one',
        ),
        agentProfile: AuthMeAgentProfile(
          profileId: 'f71ebd0f-8d75-4a09-9a72-13906ae2dfc8',
          profileFile: AuthMeProfileFile(
            url: 'test/20230414105932-img-2845-ad6c5309-8fa9-44e5-8d80-72e7b977ebe8.jpg',
          ),
          profilePreviewLink:
              'https://cdn.example.com/agent-preview.jpg?token=two',
        ),
      );

      expect(
        authMe.profilePhotoCacheKey,
        'profile-photo:test/20230414105932-img-2845-ad6c5309-8fa9-44e5-8d80-72e7b977ebe8.jpg',
      );
    });
  });
}
