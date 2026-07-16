import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/clients_list_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';

void main() {
  group('ClientsListState', () {
    late FakeClientRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeClientRepository();
      container = ProviderContainer(
        overrides: [
          clientRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadInitial stores clients and total', () async {
      await container.read(clientsListStateProvider.notifier).loadInitial();

      final state = container.read(clientsListStateProvider);

      expect(state.items, hasLength(1));
      expect(state.totalItems, 1);
      expect(state.items.first.id, 'client-1');
    });

    test('loadInitial forces network refresh on cold start', () async {
      await container.read(clientsListStateProvider.notifier).loadInitial();

      expect(repository.lastClientsForceRefresh, isTrue);
    });

    test('loadInitial uses cache after session is hydrated', () async {
      container.read(networkFetchSessionProvider.notifier).markSessionHydrated();

      await container.read(clientsListStateProvider.notifier).loadInitial();

      expect(repository.lastClientsForceRefresh, isFalse);
    });

    test('loadInitial forces network refresh after session reset', () async {
      container.read(networkFetchSessionProvider.notifier).markSessionHydrated();
      container.read(networkFetchSessionProvider.notifier).resetSession();

      await container.read(clientsListStateProvider.notifier).loadInitial();

      expect(repository.lastClientsForceRefresh, isTrue);
    });

    test('search passes query to repository request', () async {
      await container.read(clientsListStateProvider.notifier).search('Aspen');

      expect(repository.lastClientsRequest?.search, 'Aspen');
      expect(repository.lastClientsRequest?.page, 1);
    });

    test('loadInitial failure stores error', () async {
      repository.fetchClientsResult = Failure(
        HttpException(
          message: 'Unable to load clients',
          errorType: HttpErrorType.client,
        ),
      );

      await container.read(clientsListStateProvider.notifier).loadInitial();

      final state = container.read(clientsListStateProvider);

      expect(state.isInitialError, isTrue);
      expect(state.operation.errorMessage, 'Unable to load clients');
    });

    test('refresh forces network refresh', () async {
      container.read(networkFetchSessionProvider.notifier).markSessionHydrated();
      await container.read(clientsListStateProvider.notifier).loadInitial();
      expect(repository.lastClientsForceRefresh, isFalse);

      await container.read(clientsListStateProvider.notifier).refresh();

      expect(repository.lastClientsForceRefresh, isTrue);
      expect(repository.lastClientsRequest?.page, 1);
    });

    test('refresh ignores stale loadMore response', () async {
      final page2Gate = Completer<void>();
      repository.fetchClientsPage2Delay = page2Gate.future;
      repository.fetchClientsResult = Success(
        PaginatedResult(
          items: const [
            ClientListItem(
              id: 'client-1',
              fullName: 'Aspen Michael',
              email: 'test@example.com',
              phone: '+11111111111',
              location: 'City, ST',
              avatarUrl: '',
            ),
          ],
          pagination: const PaginationMeta(
            page: 1,
            limit: 20,
            total: 2,
            totalPages: 2,
            hasNext: true,
            hasPrev: false,
          ),
        ),
      );

      final notifier = container.read(clientsListStateProvider.notifier);
      await notifier.loadInitial();

      final loadMoreFuture = notifier.loadMore();
      await notifier.refresh();
      page2Gate.complete();
      await loadMoreFuture;

      final state = container.read(clientsListStateProvider);

      expect(state.items, hasLength(1));
      expect(state.items.first.id, 'client-1');
    });

    test('loadMore appends next page items', () async {
      repository.fetchClientsResult = Success(
        PaginatedResult(
          items: const [
            ClientListItem(
              id: 'client-1',
              fullName: 'Aspen Michael',
              email: 'test@example.com',
              phone: '+11111111111',
              location: 'City, ST',
              avatarUrl: '',
            ),
          ],
          pagination: const PaginationMeta(
            page: 1,
            limit: 20,
            total: 2,
            totalPages: 2,
            hasNext: true,
            hasPrev: false,
          ),
        ),
      );

      final notifier = container.read(clientsListStateProvider.notifier);
      await notifier.loadInitial();
      await notifier.loadMore();

      final state = container.read(clientsListStateProvider);
      expect(state.items, hasLength(2));
      expect(state.items.last.id, 'client-2');
      expect(repository.lastClientsRequest?.page, 2);
    });
  });
}
