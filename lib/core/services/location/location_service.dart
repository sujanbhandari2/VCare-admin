import 'package:location/location.dart';

import 'package:vcare_admin/shared/utils/logger.dart';

enum LocationPermissionRequestStatus {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class LocationPermissionRequestResult {
  const LocationPermissionRequestResult._({
    required this.status,
    this.permissionStatus,
    this.error,
  });

  final LocationPermissionRequestStatus status;
  final PermissionStatus? permissionStatus;
  final Object? error;

  bool get isGranted => status == LocationPermissionRequestStatus.granted;

  bool get requiresAppSettings =>
      status == LocationPermissionRequestStatus.permissionDeniedForever;

  bool get requiresLocationService =>
      status == LocationPermissionRequestStatus.serviceDisabled;

  factory LocationPermissionRequestResult.granted(
    PermissionStatus permissionStatus,
  ) {
    return LocationPermissionRequestResult._(
      status: LocationPermissionRequestStatus.granted,
      permissionStatus: permissionStatus,
    );
  }

  factory LocationPermissionRequestResult.serviceDisabled() {
    return const LocationPermissionRequestResult._(
      status: LocationPermissionRequestStatus.serviceDisabled,
    );
  }

  factory LocationPermissionRequestResult.permissionDenied(
    PermissionStatus permissionStatus,
  ) {
    return LocationPermissionRequestResult._(
      status: LocationPermissionRequestStatus.permissionDenied,
      permissionStatus: permissionStatus,
    );
  }

  factory LocationPermissionRequestResult.permissionDeniedForever() {
    return const LocationPermissionRequestResult._(
      status: LocationPermissionRequestStatus.permissionDeniedForever,
      permissionStatus: PermissionStatus.deniedForever,
    );
  }

  factory LocationPermissionRequestResult.error([Object? error]) {
    return LocationPermissionRequestResult._(
      status: LocationPermissionRequestStatus.error,
      error: error,
    );
  }
}

class LocationService {
  /// Location Instance
  ///
  final Location _location;

  /// Private internal constructor
  ///
  LocationService._() : _location = Location.instance;

  /// Private instance of LocationService
  ///
  static LocationService? _instance;

  /// Lazy-loaded singleton instance of this class
  ///
  static LocationService get instance {
    if (_instance == null) {
      Logger.logMessage("LocationService is initialized!");
    }
    _instance ??= LocationService._();
    return _instance!;
  }

  /// Method to check whether location service is enabled or not
  ///
  Future<bool> isLocationEnabled() async {
    try {
      return await _isLocationEnabledOrThrow();
    } catch (e) {
      Logger.logError("[LocationService.isLocationEnabled] - $e");
      return false;
    }
  }

  /// Method to request location service
  ///
  Future<bool> requestLocationService() async {
    try {
      return await _requestLocationServiceOrThrow();
    } catch (e) {
      Logger.logError("[LocationService.requestLocationService] - $e");
      return false;
    }
  }

  /// Method to get the current location permission status
  ///
  Future<PermissionStatus?> getPermissionStatus() async {
    try {
      return await _getPermissionStatusOrThrow();
    } catch (e) {
      Logger.logError("[LocationService.getPermissionStatus] - $e");
      return null;
    }
  }

  /// Method to check whether location permission is provided or not
  ///
  Future<bool> hasPermission() async {
    final status = await getPermissionStatus();
    return status != null && _isPermissionGranted(status);
  }

  /// Method to request location permission
  ///
  Future<PermissionStatus?> requestPermissionStatus() async {
    try {
      return await _requestPermissionStatusOrThrow();
    } catch (e) {
      Logger.logError("[LocationService.requestPermissionStatus] - $e");
      return null;
    }
  }

  /// Method to request location permission
  ///
  Future<bool> requestPermission() async {
    final status = await requestPermissionStatus();
    return status != null && _isPermissionGranted(status);
  }

  /// Method to check and request location service and permission
  /// [onCompleted] -> Optional callback which will be triggered once
  /// [retries] -> Kept for backward compatibility. Automatic retries are no
  /// longer performed to avoid repeated system prompts from a single action.
  ///
  Future<LocationPermissionRequestResult> checkAndRequestLocationPermission({
    void Function(bool granted)? onCompleted,
    int retries = 2,
  }) async {
    assert(retries >= 0, 'retries must be non-negative');

    final result = await _resolveLocationPermissionRequest();
    onCompleted?.call(result.isGranted);
    return result;
  }

  /// Method to get the current location
  ///
  Future<LocationData?> getCurrentLocation() async {
    try {
      final enabled = await isLocationEnabled();

      if (!enabled) return null;

      final permission = await hasPermission();

      if (!permission) return null;

      final loc = await _location.getLocation();

      return loc;
    } catch (e) {
      Logger.logError("[LocationService.getCurrentLocation] - $e");
      return null;
    }
  }

  /// Method to check whether background mode is enabled or not
  ///
  Future<bool> isBackgroundModeEnabled() async {
    try {
      return await _location.isBackgroundModeEnabled();
    } catch (e) {
      Logger.logError("[LocationService.isBackgroundModeEnabled] - $e");
      return false;
    }
  }

  /// Method to enable/disable background mode
  ///
  Future<bool> enableBackgroundMode({bool enable = true}) async {
    try {
      return await _location.enableBackgroundMode(enable: enable);
    } catch (e) {
      Logger.logError("[LocationService.enableBackgroundMode] - $e");
      return false;
    }
  }

  /// Method to update location settings
  ///
  Future<bool> updateLocationSettings({
    LocationAccuracy? accuracy = LocationAccuracy.high,
    int? interval = 1000,
    double? distanceFilter = 0,
  }) async {
    try {
      return await _location.changeSettings(
        accuracy: accuracy,
        interval: interval,
        distanceFilter: distanceFilter,
      );
    } catch (e) {
      Logger.logError("[LocationService.updateLocationSettings] - $e");
      return false;
    }
  }

  /// Getter to listen location stream
  ///
  Stream<LocationData> get locationStream => _location.onLocationChanged;

  bool _isPermissionGranted(PermissionStatus status) {
    return status == PermissionStatus.grantedLimited ||
        status == PermissionStatus.granted;
  }

  Future<PermissionStatus> _getPermissionStatusOrThrow() {
    return _location.hasPermission();
  }

  Future<bool> _isLocationEnabledOrThrow() {
    return _location.serviceEnabled();
  }

  Future<PermissionStatus> _requestPermissionStatusOrThrow() {
    return _location.requestPermission();
  }

  Future<bool> _requestLocationServiceOrThrow() {
    return _location.requestService();
  }

  Future<LocationPermissionRequestResult>
  _resolveLocationPermissionRequest() async {
    try {
      if (!await _isLocationEnabledOrThrow()) {
        final serviceEnabled = await _requestLocationServiceOrThrow();

        if (!serviceEnabled) {
          return LocationPermissionRequestResult.serviceDisabled();
        }
      }

      final permissionStatus = await _getPermissionStatusOrThrow();

      if (_isPermissionGranted(permissionStatus)) {
        return LocationPermissionRequestResult.granted(permissionStatus);
      }

      if (permissionStatus == PermissionStatus.deniedForever) {
        return LocationPermissionRequestResult.permissionDeniedForever();
      }

      final requestedPermissionStatus = await _requestPermissionStatusOrThrow();

      if (_isPermissionGranted(requestedPermissionStatus)) {
        return LocationPermissionRequestResult.granted(
          requestedPermissionStatus,
        );
      }

      if (requestedPermissionStatus == PermissionStatus.deniedForever) {
        return LocationPermissionRequestResult.permissionDeniedForever();
      }

      return LocationPermissionRequestResult.permissionDenied(
        requestedPermissionStatus,
      );
    } catch (e) {
      Logger.logError(
        "[LocationService.checkAndRequestLocationPermission] - $e",
      );
      return LocationPermissionRequestResult.error(e);
    }
  }
}
