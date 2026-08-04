import 'package:flutter_test/flutter_test.dart';
import 'package:location_platform_interface/location_platform_interface.dart';

import 'package:vcare_admin/core/services/location/location_service.dart';
import 'package:vcare_admin/features/find_care/data/repositories/find_care_location_repository_impl.dart';
import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FindCareLocationRepositoryImpl', () {
    final defaultInstance = LocationPlatform.instance;
    late FakeLocationPlatform fakePlatform;
    late FindCareLocationRepositoryImpl repository;

    setUp(() {
      fakePlatform = FakeLocationPlatform();
      LocationPlatform.instance = fakePlatform;
      repository = FindCareLocationRepositoryImpl(
        locationService: LocationService.instance,
        reverseGeocode: (latitude, longitude) async {
          return const SearchLocation(city: 'Austin', state: 'TX');
        },
      );
    });

    tearDown(() {
      LocationPlatform.instance = defaultInstance;
    });

    test('returns success when permission granted and geocode works', () async {
      fakePlatform.serviceEnabledValue = true;
      fakePlatform.hasPermissionValue = PermissionStatus.granted;
      fakePlatform.locationData = LocationData.fromMap({
        'latitude': 30.27,
        'longitude': -97.74,
      });

      final result = await repository.detectCurrentLocation();

      expect(result, isA<CurrentLocationSuccess>());
      expect(
        (result as CurrentLocationSuccess).location.displayLabel,
        'Austin, TX',
      );
      expect(fakePlatform.getLocationCallCount, 1);
    });

    test('returns permissionDenied when request is denied', () async {
      fakePlatform.serviceEnabledValue = true;
      fakePlatform.hasPermissionValue = PermissionStatus.denied;
      fakePlatform.requestPermissionValue = PermissionStatus.denied;

      final result = await repository.detectCurrentLocation();

      expect(result, isA<CurrentLocationFailure>());
      expect(
        (result as CurrentLocationFailure).reason,
        CurrentLocationFailureReason.permissionDenied,
      );
      expect(fakePlatform.getLocationCallCount, 0);
    });

    test('returns permissionDeniedForever without re-requesting', () async {
      fakePlatform.serviceEnabledValue = true;
      fakePlatform.hasPermissionValue = PermissionStatus.deniedForever;

      final result = await repository.detectCurrentLocation();

      expect(
        (result as CurrentLocationFailure).reason,
        CurrentLocationFailureReason.permissionDeniedForever,
      );
      expect(fakePlatform.requestPermissionCallCount, 0);
    });

    test('returns serviceDisabled when service prompt is declined', () async {
      fakePlatform.serviceEnabledValue = false;
      fakePlatform.requestServiceValue = false;

      final result = await repository.detectCurrentLocation();

      expect(
        (result as CurrentLocationFailure).reason,
        CurrentLocationFailureReason.serviceDisabled,
      );
    });

    test('returns locationUnavailable when coordinates are missing', () async {
      fakePlatform.serviceEnabledValue = true;
      fakePlatform.hasPermissionValue = PermissionStatus.granted;
      fakePlatform.locationData = LocationData.fromMap({});

      final result = await repository.detectCurrentLocation();

      expect(
        (result as CurrentLocationFailure).reason,
        CurrentLocationFailureReason.locationUnavailable,
      );
    });

    test('returns geocodingFailed when reverse geocode yields null', () async {
      fakePlatform.serviceEnabledValue = true;
      fakePlatform.hasPermissionValue = PermissionStatus.granted;
      fakePlatform.locationData = LocationData.fromMap({
        'latitude': 30.27,
        'longitude': -97.74,
      });
      repository = FindCareLocationRepositoryImpl(
        locationService: LocationService.instance,
        reverseGeocode: (latitude, longitude) async => null,
      );

      final result = await repository.detectCurrentLocation();

      expect(
        (result as CurrentLocationFailure).reason,
        CurrentLocationFailureReason.geocodingFailed,
      );
    });

    test(
      'skips permission prompt when requestPermission is false and granted',
      () async {
        fakePlatform.serviceEnabledValue = true;
        fakePlatform.hasPermissionValue = PermissionStatus.granted;
        fakePlatform.locationData = LocationData.fromMap({
          'latitude': 30.27,
          'longitude': -97.74,
        });

        final result = await repository.detectCurrentLocation(
          requestPermission: false,
        );

        expect(result, isA<CurrentLocationSuccess>());
        expect(fakePlatform.requestPermissionCallCount, 0);
      },
    );

    test(
      'returns permissionDenied when requestPermission is false and missing',
      () async {
        fakePlatform.serviceEnabledValue = true;
        fakePlatform.hasPermissionValue = PermissionStatus.denied;

        final result = await repository.detectCurrentLocation(
          requestPermission: false,
        );

        expect(
          (result as CurrentLocationFailure).reason,
          CurrentLocationFailureReason.permissionDenied,
        );
        expect(fakePlatform.requestPermissionCallCount, 0);
      },
    );
  });
}

class FakeLocationPlatform extends LocationPlatform {
  bool serviceEnabledValue = true;
  bool requestServiceValue = true;
  PermissionStatus hasPermissionValue = PermissionStatus.denied;
  PermissionStatus requestPermissionValue = PermissionStatus.denied;
  LocationData? locationData;
  int requestServiceCallCount = 0;
  int requestPermissionCallCount = 0;
  int getLocationCallCount = 0;

  @override
  Future<PermissionStatus> hasPermission() async => hasPermissionValue;

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
  Future<bool> serviceEnabled() async => serviceEnabledValue;

  @override
  Future<LocationData> getLocation() async {
    getLocationCallCount += 1;
    return locationData ?? LocationData.fromMap({});
  }

  @override
  Stream<LocationData> get onLocationChanged => const Stream.empty();
}
