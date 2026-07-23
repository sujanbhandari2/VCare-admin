import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/todo/data/mappers/todo_item_mapper.dart';
import 'package:vcare_admin/features/todo/data/models/todo_item_model.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/repositories/todo_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_list_request.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';
import 'package:vcare_admin/shared/pagination/paginated_result.dart';

class TodoRepositoryImpl implements TodoRepository {
  const TodoRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<PaginatedResult<TodoItem>>> fetchTodos(
    PaginatedListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.todos,
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      return PaginatedResponseParser.parse(
        response,
        (json) => TodoItemModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ).toEntity(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<void>> chargeTransaction({
    required String transactionId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.transactionCharge(transactionId),
        const EmptyRequestBody(),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      ResponseValidator.ensureValid(response);
    });
  }
}
