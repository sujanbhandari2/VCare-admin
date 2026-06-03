import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/core/services/location/location_service.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService.checkAndRequestLocationPermission', () {
    final defaultInstance = LocationPlatform.instance;
    final service = LocationService.instance;
    late FakeLocationPlatform fakeLocationPlatform;

    setUp(() {
      fakeLocationPlatform = FakeLocationPlatform();
      LocationPlatform.instance = fakeLocationPlatform;
    });

    tearDown(() {
      LocationPlatform.instance = defaultInstance;
    });

    test('returns granted without prompting when permission already exists', () async {
      fakeLocationPlatform.serviceEnabledValue = true;
      fakeLocationPlatform.hasPermissionValue = PermissionStatus.granted;

      final result = await service.checkAndRequestLocationPermission();

      expect(result.status, LocationPermissionRequestStatus.granted);
      expect(result.isGranted, isTrue);
      expect(fakeLocationPlatform.requestServiceCallCount, 0);
      expect(fakeLocationPlatform.requestPermissionCallCount, 0);
    });

    test('returns serviceDisabled when the service prompt is declined', () async {
      fakeLocationPlatform.serviceEnabledValue = false;
      fakeLocationPlatform.requestServiceValue = false;

      final result = await service.checkAndRequestLocationPermission();

      expect(result.status, LocationPermissionRequestStatus.serviceDisabled);
      expect(result.requiresLocationService, isTrue);
      expect(fakeLocationPlatform.requestServiceCallCount, 1);
      expect(fakeLocationPlatform.requestPermissionCallCount, 0);
    });

    test('returns permissionDeniedForever without requesting again', () async {
      fakeLocationPlatform.serviceEnabledValue = true;
      fakeLocationPlatform.hasPermissionValue = PermissionStatus.deniedForever;

      final result = await service.checkAndRequestLocationPermission();

      expect(
        result.status,
        LocationPermissionRequestStatus.permissionDeniedForever,
      );
      expect(result.requiresAppSettings, isTrue);
      expect(fakeLocationPlatform.requestPermissionCallCount, 0);
    });

    test('returns permissionDenied when request is denied', () async {
      fakeLocationPlatform.serviceEnabledValue = true;
      fakeLocationPlatform.hasPermissionValue = PermissionStatus.denied;
      fakeLocationPlatform.requestPermissionValue = PermissionStatus.denied;

      final result = await service.checkAndRequestLocationPermission();

      expect(result.status, LocationPermissionRequestStatus.permissionDenied);
      expect(result.isGranted, isFalse);
      expect(result.permissionStatus, PermissionStatus.denied);
      expect(fakeLocationPlatform.requestPermissionCallCount, 1);
    });

    test('calls the completion callback exactly once', () async {
      fakeLocationPlatform.serviceEnabledValue = true;
      fakeLocationPlatform.hasPermissionValue = PermissionStatus.denied;
      fakeLocationPlatform.requestPermissionValue = PermissionStatus.granted;

      var callbackInvocationCount = 0;
      bool? callbackValue;

      final result = await service.checkAndRequestLocationPermission(
        onCompleted: (granted) {
          callbackInvocationCount += 1;
          callbackValue = granted;
        },
      );

      expect(result.status, LocationPermissionRequestStatus.granted);
      expect(callbackInvocationCount, 1);
      expect(callbackValue, isTrue);
    });

    test('returns error when the platform throws', () async {
      fakeLocationPlatform.serviceEnabledValue = true;
      fakeLocationPlatform.hasPermissionError = StateError('permission check failed');

      final result = await service.checkAndRequestLocationPermission();

      expect(result.status, LocationPermissionRequestStatus.error);
      expect(result.error, isA<StateError>());
      expect(result.isGranted, isFalse);
    });
  });
}

class FakeLocationPlatform extends LocationPlatform {
  bool serviceEnabledValue = true;
  bool requestServiceValue = true;
  PermissionStatus hasPermissionValue = PermissionStatus.denied;
  PermissionStatus requestPermissionValue = PermissionStatus.denied;
  Object? hasPermissionError;
  int requestServiceCallCount = 0;
  int requestPermissionCallCount = 0;

  @override
  Future<PermissionStatus> hasPermission() async {
    if (hasPermissionError != null) {
      throw hasPermissionError!;
    }

    return hasPermissionValue;
  }

  @override
  Stream<LocationData> get onLocationChanged => Stream<LocationData>.empty();

  @override
  Future<PermissionStatus> requestPermission() async {
    requestPermissionCallCount += 1;
    return requestPermissionValue;
  }

  @override
  Future<bool> requestService() async {
    requestServiceCallCount += 1;
    serviceEnabledValue = requestServiceValue;
    return requestServiceValue;
  }

  @override
  Future<bool> serviceEnabled() async {
    return serviceEnabledValue;
  }
}
