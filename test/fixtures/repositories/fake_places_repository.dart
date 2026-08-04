import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';
import 'package:vcare_admin/features/places/domain/entities/places_autocomplete_type.dart';
import 'package:vcare_admin/features/places/domain/repositories/places_repository.dart';

class FakePlacesRepository implements PlacesRepository {
  EitherResponseOrException<List<PlacePrediction>> predictionsResult =
      const Success<List<PlacePrediction>, HttpException>([]);

  EitherResponseOrException<ParsedAddressParts> resolveAddressResult =
      const Success<ParsedAddressParts, HttpException>(
        ParsedAddressParts(),
      );

  EitherResponseOrException<({String city, String state})>
  resolveCityStateResult =
      const Success<({String city, String state}), HttpException>(
        (city: '', state: ''),
      );

  int fetchPredictionsCallCount = 0;
  String? lastInput;
  PlacesAutocompleteType? lastType;

  @override
  Future<EitherResponseOrException<List<PlacePrediction>>> fetchPredictions({
    required String input,
    PlacesAutocompleteType type = PlacesAutocompleteType.address,
    CancelToken? cancelToken,
  }) async {
    fetchPredictionsCallCount++;
    lastInput = input;
    lastType = type;
    return predictionsResult;
  }

  @override
  Future<EitherResponseOrException<ParsedAddressParts>> resolvePlaceAddress({
    required PlacePrediction prediction,
    CancelToken? cancelToken,
  }) async {
    return resolveAddressResult;
  }

  @override
  Future<EitherResponseOrException<({String city, String state})>>
  resolvePlaceCityState({
    required PlacePrediction prediction,
    CancelToken? cancelToken,
  }) async {
    return resolveCityStateResult;
  }
}
