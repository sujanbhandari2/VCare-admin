import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/data/mappers/auth_me_mapper.dart';
import 'package:vcare_admin/features/profile/data/models/auth_me_model.dart';

void main() {
  group('AuthMeModel', () {
    test('fromJson maps user, tenant, associations, and menu', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'id': 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
          'firstName': 'Jane',
          'middleName': null,
          'lastName': 'Doe',
          'dateOfBirth': '1990-01-15T00:00:00.000Z',
          'gender': null,
          'email': 'sujan@vitafyhealth.com',
          'phoneNumber': '+15551234567',
          'emailVerifiedAt': '2026-06-23T07:22:39.597Z',
          'status': 'ACTIVE',
          'profileImage': null,
          'profilePreviewLink': null,
          'mfaEnabled': false,
          'userType': 'CLIENT',
          'createdAt': '2026-06-23T07:22:39.599Z',
          'updatedAt': '2026-06-23T07:22:39.607Z',
          'currentTenant': {
            'id': '1b4b5118-055f-44e7-9ddd-59e5e357e756',
            'slug': 'default',
            'name': 'Default',
          },
          'currentRoles': ['CLIENT'],
          'tenantAssociations': [
            {
              'tenantId': '1b4b5118-055f-44e7-9ddd-59e5e357e756',
              'tenantSlug': 'default',
              'tenantName': 'Default',
              'roles': ['CLIENT'],
              'branchIds': [],
              'isActive': true,
              'ssoProvider': null,
              'ssoUserId': null,
            },
          ],
        },
        'menu': ['files', 'activities'],
      });

      final entity = model.toEntity();

      expect(entity.user.id, 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a');
      expect(entity.user.firstName, 'Jane');
      expect(entity.user.lastName, 'Doe');
      expect(entity.user.displayName, 'Jane Doe');
      expect(entity.user.email, 'sujan@vitafyhealth.com');
      expect(entity.user.phoneNumber, '+15551234567');
      expect(entity.user.dateOfBirth, '1990-01-15T00:00:00.000Z');
      expect(entity.user.userType, 'CLIENT');
      expect(entity.user.currentTenant?.slug, 'default');
      expect(entity.user.currentRoles, ['CLIENT']);
      expect(entity.user.tenantAssociations, hasLength(1));
      expect(entity.user.tenantAssociations.first.tenantName, 'Default');
      expect(entity.menu, ['files', 'activities']);
    });

    test('fromJson maps profilePreviewLink and agentProfile preview link', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'firstName': 'Omnis',
          'lastName': 'Porro',
          'profilePreviewLink': 'https://cdn.example.com/user-preview.jpg',
        },
        'agentProfile': {
          'profilePreviewLink': 'https://cdn.example.com/agent-preview.jpg',
          'referralLink': 'https://localhost:8080/refer/AGT-22581',
        },
        'menu': [],
      });

      final entity = model.toEntity();

      expect(entity.user.profilePreviewLink,
          'https://cdn.example.com/user-preview.jpg');
      expect(entity.agentProfile?.profilePreviewLink,
          'https://cdn.example.com/agent-preview.jpg');
      expect(entity.agentProfile?.referralLink,
          'https://localhost:8080/refer/AGT-22581');
    });

    test('fromJson maps agent profile agencyGroup', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'firstName': 'Sujan',
          'lastName': 'Bhandari',
        },
        'agentProfile': {
          'agentCode': 'AGT-52592',
          'agencyGroup': {
            'id': 'group-1',
            'name': 'Acme Insurance',
          },
        },
        'menu': [],
      });

      final entity = model.toEntity();

      expect(entity.agentProfile?.agencyGroup?.id, 'group-1');
      expect(entity.agentProfile?.agencyGroup?.name, 'Acme Insurance');
    });

    test('fromJson maps user agencyGroupId and agencyGroupName', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'firstName': 'Sujan',
          'lastName': 'bhandari',
          'agencyGroupId': 'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
          'agencyGroupName': 'Agency grouup',
        },
        'agentProfile': {
          'agentCode': 'AGT-00002',
          'agencyGroup': 'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
        },
        'menu': [],
      });

      final entity = model.toEntity();

      expect(
        entity.user.agencyGroupId,
        'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
      );
      expect(entity.user.agencyGroupName, 'Agency grouup');
      expect(
        entity.agentProfile?.agencyGroup?.id,
        'a41ff0cd-7f0e-4000-aa21-7d702dc49a18',
      );
      expect(entity.agentProfile?.agencyGroup?.name, isNull);
    });

    test('fromJson maps null agencyGroup on agent profile', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'firstName': 'Sujan',
          'lastName': 'Bhandari',
        },
        'agentProfile': {
          'agentCode': 'AGT-52592',
          'agencyGroup': null,
        },
        'menu': [],
      });

      final entity = model.toEntity();

      expect(entity.agentProfile?.agencyGroup, isNull);
    });

    test('fromJson maps agent profile personal info and address', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'firstName': 'Sujan',
          'lastName': 'bhandari',
          'email': 'sujan+222@vitafyhealth.com',
          'phoneNumber': '+13434343434',
          'dateOfBirth': '1995-07-01T00:00:00.000Z',
        },
        'agentProfile': {
          'id': 'cec6f613-2f94-4dc9-8e08-9d3961182f4d',
          'firstName': 'Sujan',
          'lastName': 'bhandari',
          'email': 'sujan+222@vitafyhealth.com',
          'phoneNumber': '+13434343434',
          'dateOfBirth': '1995-07-01T00:00:00.000Z',
          'profilePreviewLink':
              'https://cdn.example.com/agent-preview.jpg',
          'referralLink': 'https://qa-app.vcareadvocacy.com/refer/AGT-00002',
          'address': {
            'addressLine1': 'Autem eos iste rerum',
            'addressLine2': 'Et placeat mollitia',
            'city': 'Aut saepe ipsum do c',
            'state': 'Arkansas',
            'country': null,
            'postalCode': '97733',
          },
        },
        'menu': [],
      });

      final entity = model.toEntity();

      expect(entity.agentProfile?.firstName, 'Sujan');
      expect(entity.agentProfile?.lastName, 'bhandari');
      expect(entity.agentProfile?.displayName, 'Sujan bhandari');
      expect(entity.agentProfile?.email, 'sujan+222@vitafyhealth.com');
      expect(entity.agentProfile?.phoneNumber, '+13434343434');
      expect(entity.agentProfile?.address?.addressLine1,
          'Autem eos iste rerum');
      expect(entity.agentProfile?.address?.city, 'Aut saepe ipsum do c');
      expect(entity.agentProfile?.address?.postalCode, '97733');
    });

    test('fromJson maps agent profile file metadata', () {
      final model = AuthMeModel.fromJson({
        'user': {
          'firstName': 'Sujan',
          'lastName': 'bhandari',
          'profilePreviewLink':
              'https://cdn.example.com/user-preview.jpg',
        },
        'agentProfile': {
          'profileId': 'f71ebd0f-8d75-4a09-9a72-13906ae2dfc8',
          'profileFile': {
            'id': 'f71ebd0f-8d75-4a09-9a72-13906ae2dfc8',
            'name': '20230414105932_IMG_2845.jpg',
            'url':
                'test/20230414105932-img-2845-ad6c5309-8fa9-44e5-8d80-72e7b977ebe8.jpg',
          },
          'profilePreviewLink':
              'https://cdn.example.com/agent-preview.jpg',
        },
        'menu': [],
      });

      final entity = model.toEntity();

      expect(entity.user.profilePreviewLink,
          'https://cdn.example.com/user-preview.jpg');
      expect(entity.agentProfile?.profileFile?.url,
          'test/20230414105932-img-2845-ad6c5309-8fa9-44e5-8d80-72e7b977ebe8.jpg');
      expect(
        entity.profilePhotoCacheKey,
        'profile-photo:test/20230414105932-img-2845-ad6c5309-8fa9-44e5-8d80-72e7b977ebe8.jpg',
      );
    });
  });
}
