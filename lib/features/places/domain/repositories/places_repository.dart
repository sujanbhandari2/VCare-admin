import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';
import 'package:vcare_admin/features/places/domain/entities/places_autocomplete_type.dart';

abstract class PlacesRepository {
  Future<EitherResponseOrException<List<PlacePrediction>>> fetchPredictions({
    required String input,
    PlacesAutocompleteType type = PlacesAutocompleteType.address,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<ParsedAddressParts>> resolvePlaceAddress({
    required PlacePrediction prediction,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<({String city, String state})>>
  resolvePlaceCityState({
    required PlacePrediction prediction,
    CancelToken? cancelToken,
  });
}
