import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/data/mappers/auth_mappers.dart';
import 'package:vcare_admin/features/auth/data/models/auth_setup_account_result_model.dart';
import 'package:vcare_admin/features/auth/data/models/auth_verify_otp_result_model.dart';

void main() {
  group('AuthVerifyOtpResultModel', () {
    test('fromJson parses registrationToken for metadata-only response', () {
      final model = AuthVerifyOtpResultModel.fromJson({
        'registrationToken': 'test-registration-token',
      });

      final entity = model.toEntity();

      expect(model.registrationToken, 'test-registration-token');
      expect(model.session, isNull);
      expect(entity.registrationToken, 'test-registration-token');
      expect(entity.session, isNull);
    });

    test('fromJson parses session when token fields are present', () {
      final model = AuthVerifyOtpResultModel.fromJson({
        'access': 'access-token',
        'refresh': 'refresh-token',
        'user_id': 42,
        'email': 'user@example.com',
      });

      final entity = model.toEntity();

      expect(model.session, isNotNull);
      expect(model.session!.access, 'access-token');
      expect(entity.session?.access, 'access-token');
      expect(entity.session?.userId, 42);
    });
  });

  group('AuthSetupAccountResultModel', () {
    test('fromJson maps nested user and tokens to session and profileId', () {
      final model = AuthSetupAccountResultModel.fromJson({
        'user': {
          'id': 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
          'firstName': 'Jane',
          'lastName': 'Doe',
          'email': 'jane@example.com',
        },
        'tokens': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
        },
        'menu': ['files', 'activities'],
      });

      final entity = model.toEntity();

      expect(model.profileId, 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a');
      expect(model.session.access, 'access-token');
      expect(model.session.refresh, 'refresh-token');
      expect(model.session.email, 'jane@example.com');
      expect(model.session.username, 'Jane Doe');
      expect(model.menu, ['files', 'activities']);
      expect(entity.profileId, 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a');
      expect(entity.session.access, 'access-token');
      expect(entity.session.refresh, 'refresh-token');
      expect(entity.session.email, 'jane@example.com');
      expect(entity.menu, ['files', 'activities']);
    });
  });
}
