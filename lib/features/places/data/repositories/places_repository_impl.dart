import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/places/data/mappers/places_mapper.dart';
import 'package:vcare_admin/features/places/data/models/place_details_model.dart';
import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/domain/entities/place_prediction.dart';
import 'package:vcare_admin/features/places/domain/entities/places_autocomplete_type.dart';
import 'package:vcare_admin/features/places/domain/repositories/places_repository.dart';
import 'package:vcare_admin/features/places/utils/parse_address_components.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  const PlacesRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<PlacePrediction>>> fetchPredictions({
    required String input,
    PlacesAutocompleteType type = PlacesAutocompleteType.address,
    CancelToken? cancelToken,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Success<List<PlacePrediction>, HttpException>([]),
      );
    }

    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.placesAutocomplete,
        queryParameters: {
          'input': trimmed,
          'type': type.apiValue,
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: true,
      );

      return ResponseValidator.parse(
        response,
        mapPlacePredictions,
      );
    });
  }

  Future<PlaceDetails> _fetchPlaceDetails({
    required String placeId,
    CancelToken? cancelToken,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.placeById(placeId),
      isAuthenticated: true,
      cancelToken: cancelToken,
      forceRefresh: true,
    );

    final model = ResponseValidator.parse(
      response,
      (data) {
        if (data is! Map) {
          return const PlaceDetailsModel(addressComponents: []);
        }
        return PlaceDetailsModel.fromJson(Map<String, dynamic>.from(data));
      },
      dataValidator: (data) => data is Map,
    );

    return model.toEntity();
  }

  @override
  Future<EitherResponseOrException<ParsedAddressParts>> resolvePlaceAddress({
    required PlacePrediction prediction,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      try {
        final details = await _fetchPlaceDetails(
          placeId: prediction.placeId,
          cancelToken: cancelToken,
        );
        final parts = parseAddressComponents(details);
        if (parts.line1.isNotEmpty ||
            parts.city.isNotEmpty ||
            parts.state.isNotEmpty ||
            parts.postalCode.isNotEmpty) {
          final fromLabel = parseAddressLabel(prediction.label);
          return ParsedAddressParts(
            line1: parts.line1.isNotEmpty ? parts.line1 : fromLabel.line1,
            city: parts.city.isNotEmpty ? parts.city : fromLabel.city,
            state: parts.state.isNotEmpty ? parts.state : fromLabel.state,
            postalCode: parts.postalCode.isNotEmpty
                ? parts.postalCode
                : fromLabel.postalCode,
          );
        }
      } catch (_) {
        // Fall through to label parse.
      }
      return parseAddressLabel(prediction.label);
    });
  }

  @override
  Future<EitherResponseOrException<({String city, String state})>>
  resolvePlaceCityState({
    required PlacePrediction prediction,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      try {
        final details = await _fetchPlaceDetails(
          placeId: prediction.placeId,
          cancelToken: cancelToken,
        );
        final parts = parseCityStateFromPlace(details);
        if (parts.city.isNotEmpty || parts.state.isNotEmpty) {
          final fromLabel = parseCityStateLabel(prediction.label);
          return (
            city: parts.city.isNotEmpty ? parts.city : fromLabel.city,
            state: parts.state.isNotEmpty ? parts.state : fromLabel.state,
          );
        }
      } catch (_) {
        // Fall through to label parse.
      }
      return parseCityStateLabel(prediction.label);
    });
  }
}
