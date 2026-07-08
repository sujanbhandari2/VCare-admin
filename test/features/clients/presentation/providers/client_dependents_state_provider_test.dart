import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_dependents_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';

void main() {
  group('ClientDependentsState', () {
    late FakeClientRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeClientRepository();
      repository.fetchDependentsResult = Success(
        PaginatedResult(
          items: const [
            ClientDependent(
              id: 'dependent-1',
              name: 'Quemby Perry',
              relation: 'Spouse',
              avatarUrl: '',
            ),
          ],
          pagination: const PaginationMeta(
            page: 1,
            limit: 20,
            total: 1,
            totalPages: 1,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );
      container = ProviderContainer(
        overrides: [
          clientRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchDependents stores dependents', () async {
      await container
          .read(clientDependentsStateProvider('client-1').notifier)
          .fetchDependents();

      final state = container.read(clientDependentsStateProvider('client-1'));

      expect(state.fetching, isFalse);
      expect(state.dependents, hasLength(1));
      expect(state.dependents.first.id, 'dependent-1');
      expect(state.dependents.first.name, 'Quemby Perry');
      expect(repository.lastClientId, 'client-1');
      expect(repository.lastDependentsRequest?.page, 1);
      expect(repository.lastDependentsRequest?.limit, 20);
    });

    test('fetchDependents forces network refresh', () async {
      await container
          .read(clientDependentsStateProvider('client-1').notifier)
          .fetchDependents();

      expect(repository.lastDependentsForceRefresh, isTrue);
    });
  });
}
