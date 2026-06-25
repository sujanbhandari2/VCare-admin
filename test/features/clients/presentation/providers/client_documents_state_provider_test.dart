import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_documents_state_provider.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';

void main() {
  group('ClientDocumentsState', () {
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

    test('loadInitial stores documents and total', () async {
      repository.fetchDocumentsResult = Success(
        PaginatedResult(
          items: const [
            ClientFile(
              id: 'doc-1',
              name: 'insurance-card.jpg',
              size: '—',
              uploadedAt: '2026-06-25T06:15:24.432Z',
              url: 'https://example.com/api/test/insurance-card.jpg',
              mime: 'image/jpeg',
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

      await container
          .read(clientDocumentsStateProvider('client-1').notifier)
          .loadInitial();

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(state.items, hasLength(1));
      expect(state.totalItems, 1);
      expect(state.items.first.name, 'insurance-card.jpg');
      expect(repository.lastClientId, 'client-1');
      expect(repository.lastDocumentsRequest?.page, 1);
    });

    test('loadInitial failure stores error', () async {
      repository.fetchDocumentsResult = Failure(
        HttpException(message: 'Unable to load documents'),
      );

      await container
          .read(clientDocumentsStateProvider('client-1').notifier)
          .loadInitial();

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(state.isInitialError, isTrue);
      expect(state.operation.errorMessage, 'Unable to load documents');
    });

    test('loadMore appends next page items', () async {
      repository.fetchDocumentsResult = Success(
        PaginatedResult(
          items: const [
            ClientFile(
              id: 'doc-1',
              name: 'insurance-card.jpg',
              size: '—',
              uploadedAt: '2026-06-25T06:15:24.432Z',
              url: 'https://example.com/api/test/insurance-card.jpg',
              mime: 'image/jpeg',
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

      final notifier =
          container.read(clientDocumentsStateProvider('client-1').notifier);
      await notifier.loadInitial();

      repository.fetchDocumentsResult = Success(
        PaginatedResult(
          items: const [
            ClientFile(
              id: 'doc-2',
              name: 'agreement.pdf',
              size: '—',
              uploadedAt: '2026-06-24T06:15:24.432Z',
              url: 'https://example.com/api/test/agreement.pdf',
              mime: 'application/pdf',
            ),
          ],
          pagination: const PaginationMeta(
            page: 2,
            limit: 20,
            total: 2,
            totalPages: 2,
            hasNext: false,
            hasPrev: true,
          ),
        ),
      );

      await notifier.loadMore();

      final state = container.read(clientDocumentsStateProvider('client-1'));
      expect(state.items, hasLength(2));
      expect(state.items.last.id, 'doc-2');
      expect(repository.lastDocumentsRequest?.page, 2);
    });
  });
}
