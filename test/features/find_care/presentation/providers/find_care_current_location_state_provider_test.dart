import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_current_location_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_location_repository_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';

import '../../../../fixtures/repositories/fake_find_care_location_repository.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('FindCareCurrentLocationStateNotifier', () {
    late FakeFindCareLocationRepository repository;
    late InMemoryStorageService storage;
    late ProviderContainer container;

    setUp(() {
      repository = FakeFindCareLocationRepository();
      storage = InMemoryStorageService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          findCareLocationRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('detectCurrentLocation success updates search location', () async {
      repository.detectResult = const CurrentLocationSuccess(
        SearchLocation(city: 'Denver', state: 'CO'),
      );

      final result = await container
          .read(findCareCurrentLocationStateProvider.notifier)
          .detectCurrentLocation();

      final state = container.read(findCareCurrentLocationStateProvider);
      final location = container.read(findCareSearchLocationProvider);

      expect(result, isA<CurrentLocationSuccess>());
      expect(state.detecting, isFalse);
      expect(state.hasError, isFalse);
      expect(location.displayLabel, 'Denver, CO');
      expect(location.fromCurrentLocation, isTrue);
      expect(repository.detectCallCount, 1);
    });

    test(
      'detectCurrentLocation failure keeps previous search location',
      () async {
        await container
            .read(findCareSearchLocationProvider.notifier)
            .setLocation(const SearchLocation(city: 'Seattle', state: 'WA'));

        repository.detectResult = const CurrentLocationFailure(
          reason: CurrentLocationFailureReason.permissionDenied,
        );

        final result = await container
            .read(findCareCurrentLocationStateProvider.notifier)
            .detectCurrentLocation();

        final state = container.read(findCareCurrentLocationStateProvider);
        final location = container.read(findCareSearchLocationProvider);

        expect(result, isA<CurrentLocationFailure>());
        expect(state.hasError, isTrue);
        expect(
          state.lastFailureReason,
          CurrentLocationFailureReason.permissionDenied,
        );
        expect(location.displayLabel, 'Seattle, WA');
      },
    );

    test('markAutoPromptCompleted is sticky for the session', () {
      final notifier = container.read(
        findCareCurrentLocationStateProvider.notifier,
      );

      expect(
        container
            .read(findCareCurrentLocationStateProvider)
            .autoPromptCompleted,
        isFalse,
      );

      notifier.markAutoPromptCompleted();
      expect(
        container
            .read(findCareCurrentLocationStateProvider)
            .autoPromptCompleted,
        isTrue,
      );

      notifier.markAutoPromptCompleted();
      expect(
        container
            .read(findCareCurrentLocationStateProvider)
            .autoPromptCompleted,
        isTrue,
      );
    });

    test('hasPermission delegates to repository', () async {
      repository.hasPermissionValue = true;

      final granted = await container
          .read(findCareCurrentLocationStateProvider.notifier)
          .hasPermission();

      expect(granted, isTrue);
      expect(repository.hasPermissionCallCount, 1);
    });
  });
}
