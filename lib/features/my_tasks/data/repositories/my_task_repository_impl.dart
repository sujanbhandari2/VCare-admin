import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/my_tasks/data/mappers/my_task_mapper.dart';
import 'package:vcare_admin/features/my_tasks/data/models/my_task_model.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_note.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_page.dart';
import 'package:vcare_admin/features/my_tasks/domain/repositories/my_task_repository.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class MyTaskRepositoryImpl implements MyTaskRepository {
  const MyTaskRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<MyTaskPage>> fetchTasks(
    MyTaskListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.tasks,
        queryParameters: request.toQueryParameters(),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final page = PaginatedResponseParser.parse(
        response,
        (json) => MyTaskModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );

      final metricsRaw = PaginatedResponseParser.extractMetrics(response);
      final metrics = metricsRaw == null
          ? MyTaskMetrics.empty
          : MyTaskMetricsModel.fromJson(metricsRaw).toEntity();

      return MyTaskPage(
        items: page.items
            .map((model) => model.toEntity())
            .toList(growable: false),
        totalCount: page.pagination.total,
        metrics: metrics,
      );
    });
  }

  @override
  Future<EitherResponseOrException<MyTask>> fetchTask({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.task(taskId),
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );
      return _parseTask(response);
    });
  }

  @override
  Future<EitherResponseOrException<MyTask>> createTask(
    MyTaskCreateRequest request, {
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.tasks,
        JsonRequestBody(request.toJson()),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final task = _parseTask(response);
      final note = request.initialNote?.trim();
      if (note == null || note.isEmpty) return task;

      await apiClient.post(
        ApiEndpoints.taskNotes(task.id),
        JsonRequestBody({'note': note}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );
      return task;
    });
  }

  @override
  Future<EitherResponseOrException<MyTask>> updateTask({
    required String taskId,
    required MyTaskUpdateRequest request,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.task(taskId),
        JsonRequestBody(request.toJson()),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );
      return _parseTask(response);
    });
  }

  @override
  Future<EitherResponseOrException<void>> deleteTask({
    required String taskId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.task(taskId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );
      ResponseValidator.ensureValid(response);
    });
  }

  @override
  Future<EitherResponseOrException<MyTask>> snoozeTask({
    required String taskId,
    required MyTaskSnoozeRequest request,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.taskSnooze(taskId),
        JsonRequestBody(request.toJson()),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );
      return _parseTask(response);
    });
  }

  @override
  Future<EitherResponseOrException<List<MyTaskNote>>> fetchNotes({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.get(
        ApiEndpoints.taskNotes(taskId),
        queryParameters: {'page': 1, 'limit': 100, 'sortOrder': 'desc'},
        isAuthenticated: true,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      final page = PaginatedResponseParser.parse(
        response,
        (json) =>
            MyTaskNoteModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );

      // API returns newest-first; present oldest-first like the web UI.
      return page.items
          .map((model) => model.toEntity())
          .toList(growable: false)
          .reversed
          .toList(growable: false);
    });
  }

  @override
  Future<EitherResponseOrException<MyTaskNote>> addNote({
    required String taskId,
    required String note,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.post(
        ApiEndpoints.taskNotes(taskId),
        JsonRequestBody({'note': note.trim()}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) =>
            MyTaskNoteModel.fromJson(Map<String, dynamic>.from(data as Map)),
        dataValidator: MyTaskNoteModel.isValidApiData,
      );
      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<MyTaskNote>> updateNote({
    required String taskId,
    required String noteId,
    required String note,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.patch(
        ApiEndpoints.taskNote(taskId, noteId),
        JsonRequestBody({'note': note.trim()}),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) =>
            MyTaskNoteModel.fromJson(Map<String, dynamic>.from(data as Map)),
        dataValidator: MyTaskNoteModel.isValidApiData,
      );
      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<void>> deleteNote({
    required String taskId,
    required String noteId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final response = await apiClient.delete(
        ApiEndpoints.taskNote(taskId, noteId),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );
      ResponseValidator.ensureValid(response);
    });
  }

  MyTask _parseTask(Response<dynamic> response) {
    final model = ResponseValidator.parse(
      response,
      (data) => MyTaskModel.fromJson(Map<String, dynamic>.from(data as Map)),
      dataValidator: MyTaskModel.isValidApiData,
    );
    return model.toEntity();
  }
}
