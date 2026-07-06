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
  });
}
