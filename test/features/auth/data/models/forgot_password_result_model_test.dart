import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/data/mappers/auth_mappers.dart';
import 'package:vcare_admin/features/auth/data/models/forgot_password_result_model.dart';

void main() {
  group('ForgotPasswordResultModel', () {
    test('fromJson parses accounts for disambiguation', () {
      final model = ForgotPasswordResultModel.fromJson({
        'accounts': [
          {
            'accountId': 'acc-1',
            'displayName': 'Jane Doe',
          },
          {
            'accountId': 'acc-2',
            'displayName': 'John Doe',
          },
        ],
      });

      final entity = model.toEntity();

      expect(entity.requiresDisambiguation, isTrue);
      expect(entity.accounts, hasLength(2));
      expect(entity.accounts.first.accountId, 'acc-1');
      expect(entity.accounts.first.displayName, 'Jane Doe');
    });

    test('fromJson with empty accounts means reset link sent', () {
      final model = ForgotPasswordResultModel.fromJson({'sent': true});

      final entity = model.toEntity();

      expect(entity.requiresDisambiguation, isFalse);
      expect(entity.sent, isTrue);
      expect(entity.accounts, isEmpty);
    });

    test('fromJson defaults missing fields', () {
      final model = ForgotPasswordResultModel.fromJson({});

      expect(model.sent, isFalse);
      expect(model.accounts, isEmpty);
    });
  });
}
