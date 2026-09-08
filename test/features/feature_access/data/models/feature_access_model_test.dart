import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/feature_access/data/mappers/feature_access_mapper.dart';
import 'package:vcare_admin/features/feature_access/data/models/feature_access_model.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';

void main() {
  group('FeatureAccessModel.fromSettingsJson', () {
    test('maps enabled feature flags from settings payload', () {
      final model = FeatureAccessModel.fromSettingsJson({
        'features': {
          'caseManagement': true,
          'healthChat': true,
          'membership': false,
        },
      });

      expect(model.caseManagement, isTrue);
      expect(model.healthChat, isTrue);
      expect(model.membership, isFalse);
    });

    test('fails closed when features map is missing', () {
      final model = FeatureAccessModel.fromSettingsJson({});

      expect(model.caseManagement, isFalse);
      expect(model.healthChat, isFalse);
      expect(model.membership, isFalse);
    });

    test('fails closed for null or non-boolean values', () {
      final model = FeatureAccessModel.fromSettingsJson({
        'features': {
          'caseManagement': null,
          'healthChat': 'true',
          'membership': 1,
        },
      });

      expect(model.toEntity(), FeatureAccess.disabled);
    });
  });
}
