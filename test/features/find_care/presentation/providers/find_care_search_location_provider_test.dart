import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/find_care/domain/entities/search_location.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_repository_provider.dart';

import '../../../../fixtures/repositories/fake_local_profile_repository.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('FindCareSearchLocation', () {
    late InMemoryStorageService storage;
    late FakeLocalProfileRepository profileRepository;
    late ProviderContainer container;

    setUp(() {
      storage = InMemoryStorageService();
      profileRepository = FakeLocalProfileRepository(
        const LocalProfile(
          firstName: 'Agent',
          lastName: 'User',
          email: 'agent@gmail.com',
          phone: '+15551234567',
          dob: '01/15/1990',
          primaryCity: 'Tampa',
          primaryState: 'Florida',
        ),
      );
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          localProfileRepositoryProvider.overrideWith(
            (ref) => profileRepository,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to profile city and state when nothing is stored', () {
      final location = container.read(findCareSearchLocationProvider);

      expect(location.city, 'Tampa');
      expect(location.state, 'FL');
      expect(location.fromCurrentLocation, isFalse);
    });

    test('setFromCurrentLocation marks GPS source', () async {
      await container
          .read(findCareSearchLocationProvider.notifier)
          .setFromCurrentLocation(
            const SearchLocation(city: 'Denver', state: 'CO'),
          );

      final location = container.read(findCareSearchLocationProvider);
      expect(location.displayLabel, 'Denver, CO');
      expect(location.fromCurrentLocation, isTrue);
    });

    test('useProfileLocation clears current-location mode', () async {
      await container
          .read(findCareSearchLocationProvider.notifier)
          .setFromCurrentLocation(
            const SearchLocation(city: 'Denver', state: 'CO'),
          );

      await container
          .read(findCareSearchLocationProvider.notifier)
          .useProfileLocation();

      final location = container.read(findCareSearchLocationProvider);
      expect(location.displayLabel, 'Tampa, FL');
      expect(location.fromCurrentLocation, isFalse);
    });

    test('setFromDisplayText clears current-location mode', () async {
      await container
          .read(findCareSearchLocationProvider.notifier)
          .setFromCurrentLocation(
            const SearchLocation(city: 'Denver', state: 'CO'),
          );

      await container
          .read(findCareSearchLocationProvider.notifier)
          .setFromDisplayText('Austin, TX');

      final location = container.read(findCareSearchLocationProvider);
      expect(location.displayLabel, 'Austin, TX');
      expect(location.fromCurrentLocation, isFalse);
    });
  });
}
