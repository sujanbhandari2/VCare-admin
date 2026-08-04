import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/utils/parse_address_components.dart';
import 'package:vcare_admin/shared/utils/us_states.dart';

void main() {
  group('normalizeZip', () {
    test('strips non-digits and truncates to 5', () {
      expect(normalizeZip('94103-1234'), '94103');
      expect(normalizeZip('94 103'), '94103');
      expect(normalizeZip('abc'), '');
    });
  });

  group('toFullStateName / toStateAbbreviation', () {
    test('maps codes and names', () {
      expect(toFullStateName('MT'), 'Montana');
      expect(toFullStateName('montana'), 'Montana');
      expect(toStateAbbreviation('Louisiana'), 'LA');
      expect(toStateAbbreviation('la'), 'LA');
    });
  });

  group('formatPrimaryLocation / parsePrimaryLocationInput', () {
    test('formats city and full state name', () {
      expect(formatPrimaryLocation('Tampa', 'FL'), 'Tampa, Florida');
      expect(formatPrimaryLocation('Tampa', ''), 'Tampa');
      expect(formatPrimaryLocation('', 'FL'), '');
    });

    test('parses comma-separated city/state', () {
      expect(
        parsePrimaryLocationInput('New Orleans, Louisiana'),
        (city: 'New Orleans', state: 'Louisiana'),
      );
      expect(
        parsePrimaryLocationInput('Tampa, FL, USA'),
        (city: 'Tampa', state: 'Florida'),
      );
    });

    test('parses trailing state code without comma', () {
      expect(
        parsePrimaryLocationInput('Tampa FL'),
        (city: 'Tampa', state: 'Florida'),
      );
    });
  });

  group('parseAddressComponents', () {
    test('maps street, city, state, zip from components', () {
      const details = PlaceDetails(
        addressComponents: [
          PlaceAddressComponent(
            longText: '123',
            shortText: '123',
            types: ['street_number'],
          ),
          PlaceAddressComponent(
            longText: 'Market St',
            shortText: 'Market St',
            types: ['route'],
          ),
          PlaceAddressComponent(
            longText: 'San Francisco',
            shortText: 'San Francisco',
            types: ['locality'],
          ),
          PlaceAddressComponent(
            longText: 'California',
            shortText: 'CA',
            types: ['administrative_area_level_1'],
          ),
          PlaceAddressComponent(
            longText: '94103',
            shortText: '94103',
            types: ['postal_code'],
          ),
        ],
      );

      final parts = parseAddressComponents(details);
      expect(parts.line1, '123 Market St');
      expect(parts.city, 'San Francisco');
      expect(parts.state, 'California');
      expect(parts.postalCode, '94103');
    });
  });

  group('parseAddressLabel', () {
    test('parses US-style prediction label', () {
      final parts = parseAddressLabel(
        '123 Market St, San Francisco, CA 94103, USA',
      );
      expect(parts.line1, '123 Market St');
      expect(parts.city, 'San Francisco');
      expect(parts.state, 'California');
      expect(parts.postalCode, '94103');
    });

    test('handles short labels', () {
      expect(parseAddressLabel('123 Market St').line1, '123 Market St');
      expect(
        parseAddressLabel('123 Market St, San Francisco').city,
        'San Francisco',
      );
    });
  });

  group('parseCityStateFromPlace', () {
    test('reads locality and full state name', () {
      const details = PlaceDetails(
        addressComponents: [
          PlaceAddressComponent(
            longText: 'Tampa',
            shortText: 'Tampa',
            types: ['locality'],
          ),
          PlaceAddressComponent(
            longText: 'Florida',
            shortText: 'FL',
            types: ['administrative_area_level_1'],
          ),
        ],
      );
      expect(
        parseCityStateFromPlace(details),
        (city: 'Tampa', state: 'Florida'),
      );
    });
  });
}
