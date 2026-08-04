import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

abstract class TodoRepository {
  Future<EitherResponseOrException<PaginatedResult<TodoItem>>> fetchTodos(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<void>> chargeTransaction({
    required String transactionId,
    CancelToken? cancelToken,
  });
}
