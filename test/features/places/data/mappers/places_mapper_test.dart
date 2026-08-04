import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/places/data/mappers/places_mapper.dart';
import 'package:vcare_admin/features/places/data/models/place_details_model.dart';
import 'package:vcare_admin/features/places/data/models/place_prediction_model.dart';

void main() {
  group('PlacePredictionModel', () {
    test('parses placeId/label variants', () {
      final camel = PlacePredictionModel.tryParse({
        'placeId': 'abc',
        'label': '123 Main St',
      });
      expect(camel?.placeId, 'abc');
      expect(camel?.label, '123 Main St');

      final snake = PlacePredictionModel.tryParse({
        'place_id': 'xyz',
        'description': '456 Oak Ave',
      });
      expect(snake?.placeId, 'xyz');
      expect(snake?.label, '456 Oak Ave');

      expect(PlacePredictionModel.tryParse({'placeId': 'only'}), isNull);
    });
  });

  group('mapPlacePredictions', () {
    test('maps prediction list and skips invalid rows', () {
      final mapped = mapPlacePredictions({
        'predictions': [
          {'placeId': '1', 'label': 'One'},
          {'place_id': '2', 'text': 'Two'},
          {'label': 'missing id'},
          'bad',
        ],
      });
      expect(mapped.length, 2);
      expect(mapped[0].placeId, '1');
      expect(mapped[1].label, 'Two');
    });

    test('returns empty for non-map payloads', () {
      expect(mapPlacePredictions(null), isEmpty);
      expect(mapPlacePredictions([]), isEmpty);
    });
  });

  group('PlaceDetailsModel', () {
    test('parses addressComponents with mixed key styles', () {
      final model = PlaceDetailsModel.fromJson({
        'address_components': [
          {
            'long_name': 'San Francisco',
            'short_name': 'SF',
            'types': ['locality'],
          },
          {
            'longText': 'California',
            'shortText': 'CA',
            'types': ['administrative_area_level_1'],
          },
        ],
      });

      expect(model.addressComponents.length, 2);
      final entity = model.toEntity();
      expect(entity.addressComponents.first.longText, 'San Francisco');
      expect(entity.addressComponents.last.shortText, 'CA');
    });
  });
}
