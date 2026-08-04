import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_repository_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

import '../../../../fixtures/repositories/fake_todo_repository.dart';

void main() {
  group('TodoListState', () {
    late FakeTodoRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeTodoRepository();
      container = ProviderContainer(
        overrides: [todoRepositoryProvider.overrideWith((ref) => repository)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadInitial stores todos and total', () async {
      await container.read(todoListStateProvider.notifier).loadInitial();

      final state = container.read(todoListStateProvider);

      expect(state.items, hasLength(1));
      expect(state.totalItems, 1);
      expect(state.items.first.id, 'payment-failed:txn-1');
    });

    test('loadInitial forces network refresh on cold start', () async {
      await container.read(todoListStateProvider.notifier).loadInitial();

      expect(repository.lastTodosForceRefresh, isTrue);
    });

    test('loadInitial uses cache after session is hydrated', () async {
      container
          .read(networkFetchSessionProvider.notifier)
          .markSessionHydrated();

      await container.read(todoListStateProvider.notifier).loadInitial();

      expect(repository.lastTodosForceRefresh, isFalse);
    });

    test('loadInitial failure stores error', () async {
      repository.fetchTodosResult = Failure(
        HttpException(
          message: 'Unable to load todos',
          errorType: HttpErrorType.client,
        ),
      );

      await container.read(todoListStateProvider.notifier).loadInitial();

      final state = container.read(todoListStateProvider);

      expect(state.isInitialError, isTrue);
      expect(state.operation.errorMessage, 'Unable to load todos');
    });

    test('refresh forces network refresh', () async {
      container
          .read(networkFetchSessionProvider.notifier)
          .markSessionHydrated();
      await container.read(todoListStateProvider.notifier).loadInitial();
      expect(repository.lastTodosForceRefresh, isFalse);

      await container.read(todoListStateProvider.notifier).refresh();

      expect(repository.lastTodosForceRefresh, isTrue);
      expect(repository.lastTodosRequest?.page, 1);
    });

    test('loadMore appends next page', () async {
      repository.fetchTodosResult = Success(
        PaginatedResult(
          items: [
            TodoItem(
              id: 'payment-failed:txn-1',
              type: TodoType.paymentFailed,
              title: 'Payment failed',
              description: 'First',
              occurredAt: DateTime.utc(2026, 7, 21, 5),
              paymentFailedDetails: const TodoPaymentFailedDetails(
                transactionId: 'txn-1',
                payerId: 'payer-1',
                payerName: 'Jane Doe',
                amount: 10,
                currency: 'USD',
              ),
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
      repository.fetchTodosPage2Result = Success(
        PaginatedResult(
          items: [
            TodoItem(
              id: 'payment-failed:txn-2',
              type: TodoType.paymentFailed,
              title: 'Payment failed',
              description: 'Second',
              occurredAt: DateTime.utc(2026, 7, 20, 5),
              paymentFailedDetails: const TodoPaymentFailedDetails(
                transactionId: 'txn-2',
                payerId: 'payer-2',
                payerName: 'John Doe',
                amount: 20,
                currency: 'USD',
              ),
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

      await container.read(todoListStateProvider.notifier).loadInitial();
      await container.read(todoListStateProvider.notifier).loadMore();

      final state = container.read(todoListStateProvider);
      expect(state.items, hasLength(2));
      expect(state.items.last.id, 'payment-failed:txn-2');
      expect(state.hasMore, isFalse);
    });

    test('reprocessCharge refreshes list on success', () async {
      await container.read(todoListStateProvider.notifier).loadInitial();

      repository.fetchTodosResult = Success(
        PaginatedResult(
          items: const [],
          pagination: const PaginationMeta(
            page: 1,
            limit: 20,
            total: 0,
            totalPages: 0,
            hasNext: false,
            hasPrev: false,
          ),
        ),
      );

      var completed = false;
      await container
          .read(todoListStateProvider.notifier)
          .reprocessCharge(
            transactionId: 'txn-1',
            onCompleted: (success, error) {
              completed = true;
              expect(success, isTrue);
              expect(error, isNull);
            },
          );

      expect(completed, isTrue);
      expect(repository.lastChargeTransactionId, 'txn-1');
      expect(container.read(todoListStateProvider).items, isEmpty);
    });

    test('reprocessCharge reports failure without clearing list', () async {
      await container.read(todoListStateProvider.notifier).loadInitial();
      repository.chargeTransactionResult = Failure(
        HttpException(
          message: 'Charge failed',
          errorType: HttpErrorType.client,
        ),
      );

      var completed = false;
      await container
          .read(todoListStateProvider.notifier)
          .reprocessCharge(
            transactionId: 'txn-1',
            onCompleted: (success, error) {
              completed = true;
              expect(success, isFalse);
              expect(error, 'Charge failed');
            },
          );

      expect(completed, isTrue);
      expect(container.read(todoListStateProvider).items, hasLength(1));
    });

    test('reprocessCharge ignores duplicate in-flight calls', () async {
      final gate = Completer<void>();
      repository.chargeDelay = gate.future;

      await container.read(todoListStateProvider.notifier).loadInitial();

      final first = container
          .read(todoListStateProvider.notifier)
          .reprocessCharge(transactionId: 'txn-1');
      final second = container
          .read(todoListStateProvider.notifier)
          .reprocessCharge(transactionId: 'txn-1');

      gate.complete();
      await Future.wait([first, second]);

      expect(repository.chargeCallCount, 1);
    });
  });
}
