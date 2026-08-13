import 'package:dio/dio.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/http_response_validator.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/task_detail/data/mappers/task_detail_mapper.dart';
import 'package:vcare_admin/features/task_detail/data/models/task_detail_model.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/task_detail/domain/repositories/task_detail_repository.dart';

class TaskDetailRepositoryImpl implements TaskDetailRepository {
  const TaskDetailRepositoryImpl(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<EitherResponseOrException<TaskDetail>> fetchTaskDetail({
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

      return _parse(response);
    });
  }

  @override
  Future<EitherResponseOrException<TaskDetail>> updateTask({
    required String taskId,
    required String title,
    required String? description,
    required TaskDetailStatus status,
    required TaskDetailPriority priority,
    required String assignedTo,
    required String? dueDateIso,
    String? category,
    String? categoryReferenceId,
    String? clientId,
    CancelToken? cancelToken,
  }) {
    return safeNetworkCall(() async {
      final trimmedDescription = description?.trim();

      final response = await apiClient.patch(
        ApiEndpoints.task(taskId),
        JsonRequestBody({
          'title': title.trim(),
          'description': trimmedDescription == null || trimmedDescription.isEmpty
              ? null
              : trimmedDescription,
          'status': status.apiValue,
          'priority': priority.apiValue,
          'assignedTo': assignedTo,
          'dueDate': dueDateIso,
          // The linked record is read-only here, so its keys are only sent back
          // when the task already had them — never nulled out.
          'category': ?category,
          'categoryReferenceId': ?categoryReferenceId,
          'clientId': ?clientId,
        }),
        isAuthenticated: true,
        cancelToken: cancelToken,
      );

      return _parse(response);
    });
  }

  TaskDetail _parse(Response<dynamic> response) {
    final model = ResponseValidator.parse(
      response,
      (data) => TaskDetailModel.fromJson(Map<String, dynamic>.from(data as Map)),
      dataValidator: TaskDetailModel.isValidApiData,
    );

    return model.toEntity();
  }
}
