import 'package:vcare_admin/features/places/data/models/place_details_model.dart';
import 'package:vcare_admin/features/places/data/models/place_prediction_model.dart';
import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';

extension PlacePredictionModelMapper on PlacePredictionModel {
  PlacePrediction toEntity() {
    return PlacePrediction(placeId: placeId, label: label);
  }
}

extension PlaceAddressComponentModelMapper on PlaceAddressComponentModel {
  PlaceAddressComponent toEntity() {
    return PlaceAddressComponent(
      longText: longText,
      shortText: shortText,
      types: types,
    );
  }
}

extension PlaceDetailsModelMapper on PlaceDetailsModel {
  PlaceDetails toEntity() {
    return PlaceDetails(
      addressComponents: addressComponents
          .map((component) => component.toEntity())
          .toList(growable: false),
    );
  }
}

List<PlacePrediction> mapPlacePredictions(dynamic payload) {
  if (payload is! Map) return const [];
  final map = Map<String, dynamic>.from(payload);
  final predictions = map['predictions'];
  if (predictions is! List) return const [];

  final result = <PlacePrediction>[];
  for (final item in predictions) {
    if (item is! Map) continue;
    final model = PlacePredictionModel.tryParse(
      Map<String, dynamic>.from(item),
    );
    if (model != null) result.add(model.toEntity());
  }
  return result;
}
