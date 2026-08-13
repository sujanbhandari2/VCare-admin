import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';

abstract class CaseTaskRepository {
  Future<EitherResponseOrException<List<CaseTask>>> fetchTasks(
    String caseId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

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
  });

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
  });
}
