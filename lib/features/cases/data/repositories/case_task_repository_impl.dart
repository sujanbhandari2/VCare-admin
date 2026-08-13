import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/data/mappers/case_task_mapper.dart';
import 'package:vcare_admin/features/cases/data/models/case_task_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';
import 'package:vcare_admin/features/cases/domain/repositories/case_task_repository.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class CaseTaskRepositoryImpl implements CaseTaskRepository {
  const CaseTaskRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<List<CaseTask>>> fetchTasks(
    String caseId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) {
    return safeNetworkCall(() async {
      final models = await _listTasks(
        caseId: caseId,
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

      var scoped = _forCase(models, caseId);

      // Server sometimes ignores categoryReferenceId — refetch the category
      // and filter locally, matching the web `listCaseTasks` fallback.
      if (scoped.isEmpty && models.isNotEmpty) {
        final fallback = await _listTasks(
          cancelToken: cancelToken,
          forceRefresh: forceRefresh,
        );
        scoped = _forCase(fallback, caseId);
      }

      return scoped.map((model) => model.toEntity()).toList(growable: false);
    });
  }

  Future<List<CaseTaskModel>> _listTasks({
    String? caseId,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    final response = await apiClient.get(
      ApiEndpoints.tasks,
      queryParameters: {
        'category': caseTaskCategory,
        'categoryReferenceId': ?caseId,
        'page': 1,
        'limit': caseTaskListLimit,
        'sortBy': 'dueDate',
        'sortOrder': 'asc',
      },
      isAuthenticated: true,
      cancelToken: cancelToken,
      forceRefresh: forceRefresh,
    );

    final parsed = PaginatedResponseParser.parse(
      response,
      (json) => CaseTaskModel.fromJson(Map<String, dynamic>.from(json as Map)),
    );

    return parsed.items;
  }

  List<CaseTaskModel> _forCase(List<CaseTaskModel> models, String caseId) {
    return models
        .where((model) => model.categoryReferenceId == caseId)
        .toList(growable: false);
  }

  @override
  Future<EitherResponseOrException<CaseTask>> createTask({
    required String caseId,
    required String clientId,
    required String title,
    String? description,
    required CaseTaskStatus status,
    required String priority,
    String? assignedTo,
    String? dueDate,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final trimmedDescription = description?.trim();
      final trimmedAssignee = assignedTo?.trim();
      final trimmedDueDate = dueDate?.trim();

      final response = await apiClient.post(
        ApiEndpoints.tasks,
        JsonRequestBody({
          'title': title.trim(),
          if (trimmedDescription != null && trimmedDescription.isNotEmpty)
            'description': trimmedDescription,
          'status': status.apiValue,
          'priority': priority.trim().toUpperCase(),
          if (trimmedAssignee != null && trimmedAssignee.isNotEmpty)
            'assignedTo': trimmedAssignee,
          if (trimmedDueDate != null && trimmedDueDate.isNotEmpty)
            'dueDate': trimmedDueDate,
          'category': caseTaskCategory,
          'categoryReferenceId': caseId,
          'clientId': clientId,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CaseTaskModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: CaseTaskModel.isValidApiData,
      );

      return model.toEntity();
    });
  }

  @override
  Future<EitherResponseOrException<CaseTask>> updateTask(
    String taskId, {
    String? title,
    String? description,
    CaseTaskStatus? status,
    String? priority,
    String? assignedTo,
    bool clearAssignedTo = false,
    String? dueDate,
    String? clientId,
    String? caseId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final trimmedTitle = title?.trim();
      final trimmedDescription = description?.trim();
      final trimmedPriority = priority?.trim();
      final trimmedAssignee = assignedTo?.trim();
      final trimmedDueDate = dueDate?.trim();
      final trimmedClientId = clientId?.trim();
      final trimmedCaseId = caseId?.trim();

      final response = await apiClient.patch(
        ApiEndpoints.task(taskId),
        JsonRequestBody({
          if (trimmedTitle != null && trimmedTitle.isNotEmpty)
            'title': trimmedTitle,
          if (description != null) 'description': trimmedDescription,
          if (status != null) 'status': status.apiValue,
          if (trimmedPriority != null && trimmedPriority.isNotEmpty)
            'priority': trimmedPriority.toUpperCase(),
          if (clearAssignedTo)
            'assignedTo': null
          else if (trimmedAssignee != null)
            'assignedTo': trimmedAssignee.isEmpty ? null : trimmedAssignee,
          if (dueDate != null) 'dueDate': trimmedDueDate,
          if (trimmedClientId != null && trimmedClientId.isNotEmpty)
            'clientId': trimmedClientId,
          if (trimmedCaseId != null && trimmedCaseId.isNotEmpty)
            'categoryReferenceId': trimmedCaseId,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      final model = ResponseValidator.parse(
        response,
        (data) => CaseTaskModel.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
        dataValidator: CaseTaskModel.isValidApiData,
      );

      return model.toEntity();
    });
  }
}
