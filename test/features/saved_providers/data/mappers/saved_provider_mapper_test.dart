import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/saved_providers/data/mappers/saved_provider_mapper.dart';
import 'package:vcare_admin/features/saved_providers/data/models/saved_provider_model.dart';

void main() {
  group('SavedProviderMapper', () {
    test('parses saved provider list from API JSON', () {
      final models = parseSavedProviderList([
        {
          'linkId': 'link-1',
          'savedAt': '2026-07-06T05:48:15.030Z',
          'provider': {
            'id': 'provider-1',
            'npi': '1124070263',
            'addressLine1': '3 Wolfer Industrial Park',
            'addressLine2': null,
            'city': 'Spring Valley',
            'state': 'IL',
            'postalCode': '61362',
            'firstName': null,
            'lastName': '10 33 Ambulance Service Limited',
            'entityCode': 'O',
            'type': 'Ambulance Service Provider',
          },
        },
      ]);

      expect(models, hasLength(1));
      final entity = models.single.toEntity();
      expect(entity.linkId, 'link-1');
      expect(entity.provider.npi, '1124070263');
      expect(entity.provider.firstName, isNull);
      expect(entity.provider.lastName, '10 33 Ambulance Service Limited');
    });

    test('maps saved provider details to medicare lookup row', () {
      final entity = SavedProviderModel.fromJson({
        'linkId': 'link-1',
        'savedAt': '2026-07-06T05:48:15.030Z',
        'provider': {
          'id': 'provider-1',
          'npi': '1234567890',
          'addressLine1': '123 Main St',
          'city': 'Austin',
          'state': 'TX',
          'postalCode': '78701',
          'firstName': 'Jane',
          'lastName': 'Doe',
          'entityCode': 'I',
          'type': 'Physician',
        },
      }).toEntity();

      final row = entity.provider.toMedicareProviderLookupRow();

      expect(row.npi, '1234567890');
      expect(row.firstName, 'Jane');
      expect(row.lastOrOrgName, 'Doe');
      expect(row.street1, '123 Main St');
      expect(row.zip5, '78701');
      expect(row.providerType, 'Physician');
    });

    test('builds save payload from medicare lookup row', () {
      const row = MedicareProviderLookupRow(
        npi: '1234567890',
        firstName: 'Jane',
        lastOrOrgName: 'Doe',
        providerType: 'Physician',
        entityCode: 'I',
        street1: '123 Main St',
        city: 'Austin',
        state: 'TX',
        zip5: '78701',
      );

      expect(row.toSaveProviderPayload(), {
        'npi': '1234567890',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'addressLine1': '123 Main St',
        'city': 'Austin',
        'state': 'TX',
        'postalCode': '78701',
        'entityCode': 'I',
        'type': 'Physician',
      });
    });

    test('omits empty firstName for organization providers', () {
      const row = MedicareProviderLookupRow(
        npi: '1124070263',
        firstName: '',
        lastOrOrgName: '10 33 Ambulance Service Limited',
        providerType: 'Ambulance Service Provider',
        entityCode: 'O',
        street1: '3 Wolfer Industrial Park',
        city: 'Spring Valley',
        state: 'IL',
        zip5: '61362',
      );

      final payload = row.toSaveProviderPayload();

      expect(payload.containsKey('firstName'), isFalse);
      expect(payload['lastName'], '10 33 Ambulance Service Limited');
      expect(payload['entityCode'], 'O');
    });
  });
}
