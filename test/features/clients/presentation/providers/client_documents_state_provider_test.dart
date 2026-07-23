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
        overrides: [clientRepositoryProvider.overrideWith((ref) => repository)],
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
        HttpException(
          message: 'Unable to load documents',
          errorType: HttpErrorType.client,
        ),
      );

      await container
          .read(clientDocumentsStateProvider('client-1').notifier)
          .loadInitial();

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(state.isInitialError, isTrue);
      expect(state.operation.errorMessage, 'Unable to load documents');
    });

    test('addLocalFile prepends document and increments total', () async {
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

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );
      await notifier.loadInitial();
      notifier.addLocalFile(
        const ClientFile(
          id: 'local-99',
          name: 'bill.pdf',
          size: '120 KB',
          uploadedAt: '2026-06-25',
          url: 'data:application/pdf;base64,abc',
          mime: 'application/pdf',
        ),
      );

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(state.items, hasLength(2));
      expect(state.totalItems, 2);
      expect(state.items.first.name, 'bill.pdf');
    });

    test('renameDocument calls repository and updates local name', () async {
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
      repository.renameClientDocumentResult = const Success(null);

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );
      await notifier.loadInitial();
      final result = await notifier.renameDocument(
        documentId: 'doc-1',
        name: 'updated-card.jpg',
      );

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(result.success, isTrue);
      expect(repository.lastRenameDocumentId, 'doc-1');
      expect(repository.lastRenameName, 'updated-card.jpg');
      expect(state.items.single.name, 'updated-card.jpg');
    });

    test('renameDocument failure leaves document name unchanged', () async {
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
      repository.renameClientDocumentResult = Failure(
        HttpException(
          message: 'Rename failed',
          errorType: HttpErrorType.client,
        ),
      );

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );
      await notifier.loadInitial();

      final result = await notifier.renameDocument(
        documentId: 'doc-1',
        name: 'updated-card.jpg',
      );

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(result.success, isFalse);
      expect(result.error, 'Rename failed');
      expect(state.items.single.name, 'insurance-card.jpg');
    });

    test('renameLocalFile updates matching document name', () async {
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

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );
      await notifier.loadInitial();
      notifier.renameLocalFile('doc-1', 'updated-card.jpg');

      final state = container.read(clientDocumentsStateProvider('client-1'));
      expect(state.items.single.name, 'updated-card.jpg');
    });

    test('removeLocalFile removes document and decrements total', () async {
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

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );
      await notifier.loadInitial();
      notifier.removeLocalFile('doc-1');

      final state = container.read(clientDocumentsStateProvider('client-1'));
      expect(state.items, isEmpty);
      expect(state.totalItems, 0);
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

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );
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

    test(
      'uploadDocument calls repository with client id and file data',
      () async {
        repository.fetchDocumentsResult = Success(
          PaginatedResult(items: const [], pagination: PaginationMeta.empty),
        );
        repository.uploadClientDocumentResult = const Success(null);

        final notifier = container.read(
          clientDocumentsStateProvider('client-1').notifier,
        );

        await notifier.uploadDocument(
          fileName: 'insurance-card.jpg',
          bytes: const [1, 2, 3],
          documentType: 'Other',
        );

        expect(repository.lastUploadClientId, 'client-1');
        expect(repository.lastUploadFileName, 'insurance-card.jpg');
        expect(repository.lastUploadBytes, [1, 2, 3]);
        expect(repository.lastUploadDocumentType, 'Other');
        expect(repository.lastUploadDate, isNotNull);
        expect(repository.lastDocumentsRequest?.page, 1);
        expect(repository.lastDocumentsForceRefresh, isTrue);
      },
    );

    test(
      'uploadDocument failure sets upload error without clearing list',
      () async {
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

        final notifier = container.read(
          clientDocumentsStateProvider('client-1').notifier,
        );
        await notifier.loadInitial();

        repository.uploadClientDocumentResult = Failure(
          HttpException(
            message: 'Upload failed',
            errorType: HttpErrorType.client,
          ),
        );

        await notifier.uploadDocument(
          fileName: 'bill.pdf',
          bytes: const [4, 5, 6],
          documentType: 'Contract',
        );

        final state = container.read(clientDocumentsStateProvider('client-1'));

        expect(state.isUploading, isFalse);
        expect(state.uploadError, 'Upload failed');
        expect(state.items, hasLength(1));
        expect(state.items.single.id, 'doc-1');
      },
    );

    test('uploadDocument success refreshes documents list', () async {
      repository.fetchDocumentsResult = Success(
        PaginatedResult(
          items: const [
            ClientFile(
              id: 'doc-new',
              name: 'new-doc.pdf',
              size: '—',
              uploadedAt: '2026-06-25T06:15:24.432Z',
              url: 'https://example.com/api/test/new-doc.pdf',
              mime: 'application/pdf',
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
      repository.uploadClientDocumentResult = const Success(null);

      final notifier = container.read(
        clientDocumentsStateProvider('client-1').notifier,
      );

      await notifier.uploadDocument(
        fileName: 'new-doc.pdf',
        bytes: const [7, 8, 9],
        documentType: 'Agreement',
      );

      final state = container.read(clientDocumentsStateProvider('client-1'));

      expect(state.isUploading, isFalse);
      expect(state.items, hasLength(1));
      expect(state.items.single.name, 'new-doc.pdf');
      expect(repository.lastDocumentsRequest?.page, 1);
      expect(repository.lastDocumentsForceRefresh, isTrue);
    });
  });
}
