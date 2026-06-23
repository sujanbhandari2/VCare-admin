import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/auth/data/models/auth_identify_result_model.dart';
import 'package:vcare_admin/features/auth/data/mappers/auth_mappers.dart';

void main() {
  group('AuthIdentifyResultModel', () {
    test('fromJson parses all identify flags', () {
      final model = AuthIdentifyResultModel.fromJson({
        'userExists': true,
        'multipleAccounts': true,
        'atLeastOneAccountLoggedIn': false,
        'otherPendingAccount': true,
        'otpSend': true,
      });

      final entity = model.toEntity();

      expect(entity.userExists, isTrue);
      expect(entity.multipleAccounts, isTrue);
      expect(entity.atLeastOneAccountLoggedIn, isFalse);
      expect(entity.otherPendingAccount, isTrue);
      expect(entity.otpSend, isTrue);
    });

    test('fromJson defaults missing fields to false', () {
      final model = AuthIdentifyResultModel.fromJson({});

      expect(model.userExists, isFalse);
      expect(model.multipleAccounts, isFalse);
      expect(model.atLeastOneAccountLoggedIn, isFalse);
      expect(model.otherPendingAccount, isFalse);
      expect(model.otpSend, isFalse);
    });
  });
}
