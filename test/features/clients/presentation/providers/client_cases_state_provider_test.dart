import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_cases_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';

void main() {
  group('ClientCasesState', () {
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

    test('loadInitial stores cases and total', () async {
      repository.fetchCasesResult = Success(
        PaginatedResult(
          items: const [
            ClientCase(
              id: 'case-1',
              caseId: 'CASE1',
              title: 'Procedure Cost',
              status: ClientCaseStatus.requested,
              createdAt: '2026-06-25T05:58:27.500Z',
              updatedAt: '2026-06-25T05:58:27.500Z',
            ),
          ],
          pagination: const PaginationMeta(
            page: 1,
            limit: 10,
            total: 1,
            totalPages: 1,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );

      await container
          .read(clientCasesStateProvider('client-1').notifier)
          .loadInitial();

      final state = container.read(clientCasesStateProvider('client-1'));

      expect(state.items, hasLength(1));
      expect(state.totalItems, 1);
      expect(state.items.first.title, 'Procedure Cost');
      expect(repository.lastClientId, 'client-1');
      expect(repository.lastCasesRequest?.limit, 10);
    });

    test('loadInitial failure stores error', () async {
      repository.fetchCasesResult = Failure(
        HttpException(message: 'Unable to load cases'),
      );

      await container
          .read(clientCasesStateProvider('client-1').notifier)
          .loadInitial();

      final state = container.read(clientCasesStateProvider('client-1'));

      expect(state.isInitialError, isTrue);
      expect(state.operation.errorMessage, 'Unable to load cases');
    });

    test('createCase calls repository and refreshes list on success', () async {
      repository.fetchCasesResult = Success(
        PaginatedResult(
          items: const [
            ClientCase(
              id: 'case-1',
              caseId: 'CASE1',
              title: 'Procedure Cost',
              status: ClientCaseStatus.requested,
              createdAt: '2026-06-25T05:58:27.500Z',
              updatedAt: '2026-06-25T05:58:27.500Z',
            ),
          ],
          pagination: const PaginationMeta(
            page: 1,
            limit: 10,
            total: 1,
            totalPages: 1,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );

      bool? completed;
      final notifier =
          container.read(clientCasesStateProvider('client-1').notifier);

      await notifier.createCase(
        title: 'Claim denial appeal',
        description: 'Need help with enrollment.',
        onCompleted: (success, error) => completed = success,
      );

      expect(completed, isTrue);
      expect(repository.lastCreateCaseClientId, 'client-1');
      expect(repository.lastCreateCaseTitle, 'Claim denial appeal');
      expect(repository.lastCreateCaseDescription, 'Need help with enrollment.');
      expect(repository.lastCasesRequest?.page, 1);
      expect(repository.lastCasesForceRefresh, isTrue);

      final state = container.read(clientCasesStateProvider('client-1'));
      expect(state.items, hasLength(1));
      expect(state.items.first.title, 'Procedure Cost');
    });

    test('createCase reports failure without refreshing list', () async {
      repository.createClientCaseResult = Failure(
        HttpException(message: 'Unable to create case'),
      );

      bool? completed;
      String? errorMessage;
      final notifier =
          container.read(clientCasesStateProvider('client-1').notifier);

      await notifier.createCase(
        title: 'Claim denial appeal',
        description: 'Need help with enrollment.',
        onCompleted: (success, error) {
          completed = success;
          errorMessage = error;
        },
      );

      expect(completed, isFalse);
      expect(errorMessage, 'Unable to create case');
      expect(repository.lastCreateCaseTitle, 'Claim denial appeal');
    });

    test('loadMore appends next page items', () async {
      repository.fetchCasesResult = Success(
        PaginatedResult(
          items: const [
            ClientCase(
              id: 'case-1',
              caseId: 'CASE1',
              title: 'Procedure Cost',
              status: ClientCaseStatus.requested,
              createdAt: '2026-06-25T05:58:27.500Z',
              updatedAt: '2026-06-25T05:58:27.500Z',
            ),
          ],
          pagination: const PaginationMeta(
            page: 1,
            limit: 10,
            total: 2,
            totalPages: 2,
            hasNext: true,
            hasPrev: false,
          ),
        ),
      );

      final notifier =
          container.read(clientCasesStateProvider('client-1').notifier);
      await notifier.loadInitial();

      repository.fetchCasesResult = Success(
        PaginatedResult(
          items: const [
            ClientCase(
              id: 'case-2',
              caseId: 'CASE2',
              title: 'Billing Review',
              status: ClientCaseStatus.inProgress,
              createdAt: '2026-06-24T05:58:27.500Z',
              updatedAt: '2026-06-24T05:58:27.500Z',
            ),
          ],
          pagination: const PaginationMeta(
            page: 2,
            limit: 10,
            total: 2,
            totalPages: 2,
            hasNext: false,
            hasPrev: true,
          ),
        ),
      );

      await notifier.loadMore();

      final state = container.read(clientCasesStateProvider('client-1'));
      expect(state.items, hasLength(2));
      expect(state.items.last.id, 'case-2');
      expect(repository.lastCasesRequest?.page, 2);
    });
  });
}
