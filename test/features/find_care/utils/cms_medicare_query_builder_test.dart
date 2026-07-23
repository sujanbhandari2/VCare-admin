import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/find_care/utils/cms_medicare_query_builder.dart';

void main() {
  group('buildMedicareDirectorySearchQuery', () {
    test('includes lookup table and provider type filter', () {
      final params = buildMedicareDirectorySearchQuery(
        providerTypeContains: 'Pediatric',
        size: 15,
        offset: 0,
      );

      expect(params['_table'], 'lookup');
      expect(params['size'], '15');
      expect(params['offset'], '0');
      expect(params['filter[ptype][condition][value]'], 'Pediatric');
    });

    test('includes first and last name filters', () {
      final params = buildMedicareDirectorySearchQuery(
        firstName: 'Jane',
        lastName: 'Doe',
        state: 'CA',
        size: 15,
        offset: 30,
      );

      expect(
        params['filter[firstName][condition][path]'],
        'Rndrng_Prvdr_First_Name',
      );
      expect(params['filter[lastName][condition][value]'], 'Doe');
      expect(params['filter[state][condition][value]'], 'CA');
      expect(params['offset'], '30');
    });

    test('throws when no filters are provided', () {
      expect(
        () => buildMedicareDirectorySearchQuery(size: 15, offset: 0),
        throwsArgumentError,
      );
    });
  });

  group('buildMedicareProviderNpiQuery', () {
    test('filters by normalized NPI on lookup table', () {
      final params = buildMedicareProviderNpiQuery('12-34567890');

      expect(params['filter[npi][condition][value]'], '1234567890');
      expect(params['_table'], 'lookup');
      expect(params['size'], '5');
    });
  });

  group('buildMedicareProviderServicesQuery', () {
    test('filters utilization table by NPI without lookup table flag', () {
      final params = buildMedicareProviderServicesQuery('1234567890', 50, 100);

      expect(params['filter[provider][condition][path]'], 'Rndrng_NPI');
      expect(params['filter[provider][condition][value]'], '1234567890');
      expect(params['size'], '50');
      expect(params['offset'], '100');
      expect(params.containsKey('_table'), isFalse);
    });
  });

  group('parseMedicareNameSearchInput', () {
    test('maps one word to last name only', () {
      final parsed = parseMedicareNameSearchInput('Smith');
      expect(parsed.firstName, isNull);
      expect(parsed.lastName, 'Smith');
    });

    test('maps two or more words to first and last name', () {
      final parsed = parseMedicareNameSearchInput('Jane Marie Doe');
      expect(parsed.firstName, 'Jane');
      expect(parsed.lastName, 'Marie Doe');
    });
  });
}
