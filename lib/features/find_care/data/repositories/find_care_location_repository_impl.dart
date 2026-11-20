import 'package:geocoding/geocoding.dart' as geocoding;

import 'package:vcare_admin/core/services/location/location_service.dart';
import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/features/find_care/domain/repositories/find_care_location_repository.dart';
import 'package:vcare_admin/features/find_care/utils/find_care_utils.dart';
import 'package:vcare_admin/shared/utils/logger.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

typedef ReverseGeocodeFn =
    Future<SearchLocation?> Function(double latitude, double longitude);

class FindCareLocationRepositoryImpl implements FindCareLocationRepository {
  FindCareLocationRepositoryImpl({
    LocationService? locationService,
    ReverseGeocodeFn? reverseGeocode,
  }) : _locationService = locationService ?? LocationService.instance,
       _reverseGeocode = reverseGeocode ?? _defaultReverseGeocode;

  final LocationService _locationService;
  final ReverseGeocodeFn _reverseGeocode;

  @override
  Future<bool> hasPermission() {
    return _locationService.hasPermission();
  }

  @override
  Future<CurrentLocationResult> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    try {
      if (requestPermission) {
        final permissionResult = await _locationService
            .checkAndRequestLocationPermission();
        if (!permissionResult.isGranted) {
          return _failureFromPermissionResult(permissionResult);
        }
      } else {
        final enabled = await _locationService.isLocationEnabled();
        if (!enabled) {
          return const CurrentLocationFailure(
            reason: CurrentLocationFailureReason.serviceDisabled,
          );
        }

        final hasPermission = await _locationService.hasPermission();
        if (!hasPermission) {
          return const CurrentLocationFailure(
            reason: CurrentLocationFailureReason.permissionDenied,
          );
        }
      }

      final locationData = await _locationService.getCurrentLocation();
      final latitude = locationData?.latitude;
      final longitude = locationData?.longitude;
      if (locationData == null || latitude == null || longitude == null) {
        return const CurrentLocationFailure(
          reason: CurrentLocationFailureReason.locationUnavailable,
        );
      }

      final searchLocation = await _reverseGeocode(latitude, longitude);
      if (searchLocation == null) {
        return const CurrentLocationFailure(
          reason: CurrentLocationFailureReason.geocodingFailed,
        );
      }

      return CurrentLocationSuccess(searchLocation);
    } catch (error) {
      Logger.logError(
        '[FindCareLocationRepositoryImpl.detectCurrentLocation] - $error',
      );
      return CurrentLocationFailure(
        reason: CurrentLocationFailureReason.error,
        message: NetworkErrorMessage.sanitize(message: error.toString()),
      );
    }
  }

  CurrentLocationFailure _failureFromPermissionResult(
    LocationPermissionRequestResult result,
  ) {
    return switch (result.status) {
      LocationPermissionRequestStatus.serviceDisabled =>
        const CurrentLocationFailure(
          reason: CurrentLocationFailureReason.serviceDisabled,
        ),
      LocationPermissionRequestStatus.permissionDeniedForever =>
        const CurrentLocationFailure(
          reason: CurrentLocationFailureReason.permissionDeniedForever,
        ),
      LocationPermissionRequestStatus.permissionDenied =>
        const CurrentLocationFailure(
          reason: CurrentLocationFailureReason.permissionDenied,
        ),
      LocationPermissionRequestStatus.error => CurrentLocationFailure(
        reason: CurrentLocationFailureReason.error,
        message: NetworkErrorMessage.sanitize(
          message: result.error?.toString(),
        ),
      ),
      LocationPermissionRequestStatus.granted => const CurrentLocationFailure(
        reason: CurrentLocationFailureReason.error,
        message: 'Unexpected permission failure.',
      ),
    };
  }
}

Future<SearchLocation?> _defaultReverseGeocode(
  double latitude,
  double longitude,
) async {
  final placemarks = await geocoding.Geocoding().placemarkFromCoordinates(
    latitude,
    longitude,
  );
  if (placemarks.isEmpty) return null;

  for (final placemark in placemarks) {
    final location = searchLocationFromAddressParts(
      locality: placemark.locality,
      subAdministrativeArea: placemark.subAdministrativeArea,
      subLocality: placemark.subLocality,
      administrativeArea: placemark.administrativeArea,
    );
    if (location != null) return location;
  }
  return null;
}
