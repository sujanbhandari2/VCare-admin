import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/domain/repositories/todo_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';
import 'package:vcare_admin/shared/pagination/pagination_meta.dart';

class FakeTodoRepository implements TodoRepository {
  EitherResponseOrException<PaginatedResult<TodoItem>> fetchTodosResult =
      Success(
        PaginatedResult(
          items: [
            TodoItem(
              id: 'payment-failed:txn-1',
              type: TodoType.paymentFailed,
              title: 'Payment failed',
              description: "Jane Doe's payment of USD 99.5 failed",
              occurredAt: DateTime.utc(2026, 7, 21, 5),
              resource: const TodoResource(type: 'TRANSACTION', id: 'txn-1'),
              paymentFailedDetails: const TodoPaymentFailedDetails(
                transactionId: 'txn-1',
                payerId: 'payer-1',
                payerName: 'Jane Doe',
                amount: 99.5,
                currency: 'USD',
                invoiceNumber: 'INV-100',
                failureReason: 'Insufficient funds',
              ),
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

  EitherResponseOrException<void> chargeTransactionResult = const Success(null);

  PaginatedListRequest? lastTodosRequest;
  bool? lastTodosForceRefresh;
  String? lastChargeTransactionId;
  int chargeCallCount = 0;
  Future<void>? chargeDelay;

  EitherResponseOrException<PaginatedResult<TodoItem>>? fetchTodosPage2Result;
  Future<void>? fetchTodosPage2Delay;

  @override
  Future<EitherResponseOrException<PaginatedResult<TodoItem>>> fetchTodos(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    lastTodosRequest = request;
    lastTodosForceRefresh = forceRefresh;

    if (request.page == 2) {
      if (fetchTodosPage2Delay != null) {
        await fetchTodosPage2Delay;
      }
      return fetchTodosPage2Result ??
          Success(
            PaginatedResult(
              items: const [],
              pagination: const PaginationMeta(
                page: 2,
                limit: 20,
                total: 1,
                totalPages: 1,
                hasNext: false,
                hasPrev: true,
              ),
            ),
          );
    }

    return fetchTodosResult;
  }

  @override
  Future<EitherResponseOrException<void>> chargeTransaction({
    required String transactionId,
    CancelToken? cancelToken,
  }) async {
    chargeCallCount += 1;
    lastChargeTransactionId = transactionId;
    if (chargeDelay != null) {
      await chargeDelay;
    }
    return chargeTransactionResult;
  }
}
