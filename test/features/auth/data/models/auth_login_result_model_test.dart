import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/data/mappers/auth_mappers.dart';
import 'package:vcare_admin/features/auth/data/models/auth_login_result_model.dart';

void main() {
  group('AuthLoginResultModel', () {
    test('fromJson maps nested user and tokens to session and profileId', () {
      final model = AuthLoginResultModel.fromJson({
        'user': {
          'id': 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
          'firstName': 'Jane',
          'lastName': 'Doe',
          'email': 'sujan@vitafyhealth.com',
          'currentTenant': {
            'id': '1b4b5118-055f-44e7-9ddd-59e5e357e756',
            'slug': 'default',
            'name': 'Default',
          },
        },
        'tokens': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
        'menu': ['files', 'activities'],
      });

      final entity = model.toEntity();

      expect(entity.access, 'access-token');
      expect(entity.refresh, 'refresh-token');
      expect(entity.email, 'sujan@vitafyhealth.com');
      expect(entity.username, 'Jane Doe');
      expect(entity.profileId, 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a');
      expect(entity.tenantId, '1b4b5118-055f-44e7-9ddd-59e5e357e756');
      expect(model.menu, ['files', 'activities']);
    });
  });
}
