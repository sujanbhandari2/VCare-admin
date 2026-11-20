import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

enum CurrentLocationFailureReason {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  locationUnavailable,
  geocodingFailed,
  error,
}

sealed class CurrentLocationResult {
  const CurrentLocationResult();

  bool get isSuccess => this is CurrentLocationSuccess;

  T when<T>({
    required T Function(SearchLocation location) success,
    required T Function(CurrentLocationFailure failure) failure,
  });
}

class CurrentLocationSuccess extends CurrentLocationResult {
  const CurrentLocationSuccess(this.location);

  final SearchLocation location;

  @override
  T when<T>({
    required T Function(SearchLocation location) success,
    required T Function(CurrentLocationFailure failure) failure,
  }) {
    return success(location);
  }
}

class CurrentLocationFailure extends CurrentLocationResult {
  const CurrentLocationFailure({required this.reason, this.message});

  final CurrentLocationFailureReason reason;
  final String? message;

  String get userMessage {
    if (message != null && message!.trim().isNotEmpty) {
      return NetworkErrorMessage.sanitize(message: message);
    }
    return switch (reason) {
      CurrentLocationFailureReason.permissionDenied =>
        'Location permission was denied. Tap the locate button to try again.',
      CurrentLocationFailureReason.permissionDeniedForever =>
        'Location permission is blocked. Enable it in your device settings.',
      CurrentLocationFailureReason.serviceDisabled =>
        'Location services are turned off. Enable them to search nearby.',
      CurrentLocationFailureReason.locationUnavailable =>
        'Unable to read your current location. Please try again.',
      CurrentLocationFailureReason.geocodingFailed =>
        'Found your coordinates, but could not resolve a city and state.',
      CurrentLocationFailureReason.error =>
        'Something went wrong while detecting your location.',
    };
  }

  @override
  T when<T>({
    required T Function(SearchLocation location) success,
    required T Function(CurrentLocationFailure failure) failure,
  }) {
    return failure(this);
  }
}
