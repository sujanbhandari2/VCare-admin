import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/help_support/data/mappers/contact_support_result_mapper.dart';
import 'package:vcare_admin/features/help_support/data/models/contact_support_result_model.dart';

void main() {
  group('ContactSupportResultModelMapper', () {
    test('maps type to entity', () {
      const model = ContactSupportResultModel(type: 'support');
      final entity = model.toEntity();
      expect(entity.type, 'support');
    });

    test('fromJson reads type', () {
      final model = ContactSupportResultModel.fromJson({'type': 'support'});
      expect(model.type, 'support');
    });

    test('fromJson falls back to empty type', () {
      final model = ContactSupportResultModel.fromJson({});
      expect(model.type, '');
    });
  });
}
