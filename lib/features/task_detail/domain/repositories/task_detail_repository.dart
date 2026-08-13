import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';

abstract class TaskDetailRepository {
  Future<EitherResponseOrException<TaskDetail>> fetchTaskDetail({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  });

  /// Saves the editable fields of a task. [dueDateIso] `null` clears the due
  /// date, matching the web drawer's update payload.
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
  });
}
