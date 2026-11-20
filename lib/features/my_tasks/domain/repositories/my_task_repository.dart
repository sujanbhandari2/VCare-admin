import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_note.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_page.dart';

abstract class MyTaskRepository {
  Future<EitherResponseOrException<MyTaskPage>> fetchTasks(
    MyTaskListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  });

  Future<EitherResponseOrException<MyTask>> fetchTask({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  });

  Future<EitherResponseOrException<MyTask>> createTask(
    MyTaskCreateRequest request, {
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<MyTask>> updateTask({
    required String taskId,
    required MyTaskUpdateRequest request,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> deleteTask({
    required String taskId,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<MyTask>> snoozeTask({
    required String taskId,
    required MyTaskSnoozeRequest request,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<List<MyTaskNote>>> fetchNotes({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  });

  Future<EitherResponseOrException<MyTaskNote>> addNote({
    required String taskId,
    required String note,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<MyTaskNote>> updateNote({
    required String taskId,
    required String noteId,
    required String note,
    CancelToken? cancelToken,
  });

  Future<EitherResponseOrException<void>> deleteNote({
    required String taskId,
    required String noteId,
    CancelToken? cancelToken,
  });
}
