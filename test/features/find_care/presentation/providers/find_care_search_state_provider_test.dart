import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/find_care/domain/entities/medicare_provider_results.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/medicare_provider_repository_provider.dart';

import '../../../../fixtures/repositories/fake_medicare_provider_repository.dart';

void main() {
  group('FindCareSearchStateNotifier', () {
    late FakeMedicareProviderRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeMedicareProviderRepository();
      container = ProviderContainer(
        overrides: [
          medicareProviderRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('runSearch loads providers from repository', () async {
      repository.searchDirectoryResult = Success(
        MedicareProviderLookupResult(
          items: const [sampleMedicareProviderItem],
          headers: const ['Rndrng_NPI'],
        ),
      );

      container
          .read(findCareSearchStateProvider.notifier)
          .setProviderQuery('Jane Doe');

      final success = await container
          .read(findCareSearchStateProvider.notifier)
          .runSearch();

      final state = container.read(findCareSearchStateProvider);
      expect(success, isTrue);
      expect(state.items, hasLength(1));
      expect(state.items.first.row.npi, '1234567890');
      expect(repository.searchDirectoryCallCount, 1);
    });

    test('runSearch sets error on failure', () async {
      repository.searchDirectoryResult = Failure(
        HttpException(title: 'Error', message: 'CMS directory error'),
      );

      container
          .read(findCareSearchStateProvider.notifier)
          .setProviderQuery('Jane Doe');

      await container.read(findCareSearchStateProvider.notifier).runSearch();

      final state = container.read(findCareSearchStateProvider);
      expect(state.items, isEmpty);
      expect(state.error, 'CMS directory error');
    });
  });
}
