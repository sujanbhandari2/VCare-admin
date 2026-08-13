import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_page.dart';
import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_request.dart';

abstract class AdminDashboardRepository {
  Future<EitherResponseOrException<AdminDashboardTodoPage>> fetchTodoList(
    AdminDashboardTodoRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<int>> fetchOpenTasksCount({
    required String userId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<int>> fetchOpenCasesCount({
    required String userId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<int>> fetchPendingMembershipsCount({
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<int>> fetchPendingDocumentsCount({
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  /// Marks a task complete — parity with web dashboard `{ status: "DONE" }`.
  Future<EitherResponseOrException<void>> completeTask({
    required String taskId,
    CancelToken? cancelToken,
  });
}
