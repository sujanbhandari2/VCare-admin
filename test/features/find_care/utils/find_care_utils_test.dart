import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_lookup_row.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';

void main() {
  group('find_care_utils', () {
    test('normalizeNpi strips non-digits', () {
      expect(normalizeNpi('12-34567890'), '1234567890');
    });

    test('formatMedicareProviderName uses org name for organizations', () {
      const row = MedicareProviderLookupRow(
        npi: '1234567890',
        firstName: 'Ignored',
        lastOrOrgName: 'City Clinic',
        providerType: 'Clinic',
        entityCode: 'O',
        street1: '123 Main',
        city: 'SF',
        state: 'CA',
        zip5: '94102',
      );

      expect(formatMedicareProviderName(row), 'City Clinic');
    });

    test('dedupeMedicareProviderItems keeps first occurrence by NPI', () {
      const duplicate = MedicareProviderListItem(
        row: MedicareProviderLookupRow(
          npi: '1111111111',
          firstName: 'A',
          lastOrOrgName: 'One',
          providerType: 'Medicine',
          entityCode: 'I',
          street1: '1',
          city: 'SF',
          state: 'CA',
          zip5: '94102',
        ),
      );
      const other = MedicareProviderListItem(
        row: MedicareProviderLookupRow(
          npi: '2222222222',
          firstName: 'B',
          lastOrOrgName: 'Two',
          providerType: 'Medicine',
          entityCode: 'I',
          street1: '2',
          city: 'SF',
          state: 'CA',
          zip5: '94102',
        ),
      );

      final deduped = dedupeMedicareProviderItems([
        duplicate,
        duplicate,
        other,
      ]);

      expect(deduped, hasLength(2));
      expect(deduped.first.row.npi, '1111111111');
    });

    test('parseSearchState extracts two-letter state code', () {
      expect(parseSearchState('San Francisco, CA'), 'CA');
      expect(parseSearchState('Seattle'), isNull);
    });

    test('normalizeUsStateCode maps names and abbreviations', () {
      expect(normalizeUsStateCode('ca'), 'CA');
      expect(normalizeUsStateCode('Texas'), 'TX');
      expect(normalizeUsStateCode(''), isNull);
      expect(normalizeUsStateCode(null), isNull);
    });

    test('searchLocationFromAddressParts builds city/state', () {
      final location = searchLocationFromAddressParts(
        locality: 'Austin',
        administrativeArea: 'Texas',
      );

      expect(location?.city, 'Austin');
      expect(location?.state, 'TX');
      expect(
        searchLocationFromAddressParts(locality: '', administrativeArea: ''),
        isNull,
      );
    });
  });
}
