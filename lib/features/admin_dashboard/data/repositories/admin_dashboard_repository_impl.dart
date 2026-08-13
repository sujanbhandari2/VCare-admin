import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/admin_dashboard/data/mappers/admin_dashboard_todo_mapper.dart';
import 'package:vcare_admin/features/admin_dashboard/data/models/admin_dashboard_todo_item_model.dart';
import 'package:vcare_admin/features/admin_dashboard/data/models/admin_dashboard_todo_metrics_model.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_page.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_request.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:vcare_admin/features/cases/domain/entities/cases_list_request.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  const AdminDashboardRepositoryImpl(this.apiClient, this.caseRepository);

  final ApiClient apiClient;
  final CaseRepository caseRepository;

  @override
  Future<EitherResponseOrException<AdminDashboardTodoPage>> fetchTodoList(
    AdminDashboardTodoRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.adminTodoList,
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final page = PaginatedResponseParser.parse(
        response,
        (json) => AdminDashboardTodoItemModel.fromJson(
          Map<String, dynamic>.from(json as Map),
        ),
      );

      final metricsRaw = PaginatedResponseParser.extractMetrics(response);
      final metrics = metricsRaw == null
          ? AdminDashboardTodoMetricsModel()
          : AdminDashboardTodoMetricsModel.fromJson(metricsRaw);

      final items = page.items
          .map((model) => model.toEntity())
          .whereType<AdminDashboardTodoItem>()
          .toList(growable: false);

      return AdminDashboardTodoPage(
        items: items,
        totalCount: page.pagination.total,
        metrics: metrics.toEntity(),
      );
    });
  }

  @override
  Future<EitherResponseOrException<int>> fetchOpenTasksCount({
    required String userId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.tasks,
        queryParameters: {
          'page': 1,
          'limit': 1,
          'assignedToUser': userId,
          'type': 'OPEN',
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final page = PaginatedResponseParser.parse(
        response,
        (json) => json,
      );

      return page.pagination.total;
    });
  }

  @override
  Future<EitherResponseOrException<int>> fetchOpenCasesCount({
    required String userId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final result = await caseRepository.fetchCases(
      CasesListRequest(
        page: 1,
        limit: 1,
        assignedTo: userId,
        bookmarkedFirst: false,
      ),
      cancelToken: cancelToken,
      forceRefresh: forceRefresh,
    );

    return result.when(
      failure: (error) => Failure<int, HttpException>(error),
      success: (page) => Success<int, HttpException>(page.pagination.total),
    );
  }

  @override
  Future<EitherResponseOrException<int>> fetchPendingMembershipsCount({
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.enrollments,
        queryParameters: {
          'page': 1,
          'limit': 1,
          'status': 'SUBMITTED',
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final page = PaginatedResponseParser.parse(
        response,
        (json) => json,
      );

      return page.pagination.total;
    });
  }

  @override
  Future<EitherResponseOrException<int>> fetchPendingDocumentsCount({
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.agents,
        queryParameters: {
          'page': 1,
          'limit': 1,
          'documentsVerified': false,
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
        },
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final page = PaginatedResponseParser.parse(
        response,
        (json) => json,
      );

      return page.pagination.total;
    });
  }

  @override
  Future<EitherResponseOrException<void>> completeTask({
    required String taskId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.task(taskId),
        const JsonRequestBody({'status': 'DONE'}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );
      ResponseValidator.ensureValid(response);
    });
  }
}
