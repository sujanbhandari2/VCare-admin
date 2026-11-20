import 'package:dio/dio.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_note.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_page.dart';
import 'package:vcare_admin/features/my_tasks/domain/repositories/my_task_repository.dart';

MyTask sampleMyTask({
  String id = 'task-1',
  String title = 'Follow up',
  MyTaskStatus status = MyTaskStatus.toDo,
  MyTaskPriority priority = MyTaskPriority.medium,
  MyTaskPerson? assignee,
  DateTime? dueDate,
  DateTime? snoozedTill,
}) {
  return MyTask(
    id: id,
    title: title,
    status: status,
    priority: priority,
    createdAt: DateTime.utc(2026, 1, 1, 10),
    assignee: assignee,
    dueDate: dueDate,
    snoozedTill: snoozedTill,
  );
}

class FakeMyTaskRepository implements MyTaskRepository {
  EitherResponseOrException<MyTaskPage> fetchTasksResult = Success(
    MyTaskPage(
      items: [sampleMyTask()],
      totalCount: 1,
      metrics: const MyTaskMetrics(open: 1, overdue: 0, dueSoon: 0),
    ),
  );

  EitherResponseOrException<MyTaskPage>? fetchTasksPage2Result;

  EitherResponseOrException<MyTask> fetchTaskResult = Success(sampleMyTask());
  EitherResponseOrException<MyTask> createTaskResult = Success(sampleMyTask());
  EitherResponseOrException<MyTask> updateTaskResult = Success(
    sampleMyTask(status: MyTaskStatus.done),
  );
  EitherResponseOrException<void> deleteTaskResult = const Success(null);
  EitherResponseOrException<MyTask> snoozeTaskResult = Success(
    sampleMyTask(snoozedTill: DateTime.utc(2026, 2, 1, 9)),
  );
  EitherResponseOrException<List<MyTaskNote>> fetchNotesResult = const Success(
    [],
  );
  EitherResponseOrException<MyTaskNote> addNoteResult = Success(
    MyTaskNote(
      id: 'note-1',
      taskId: 'task-1',
      text: 'Hello',
      createdAt: DateTime.utc(2026, 1, 1, 11),
      updatedAt: DateTime.utc(2026, 1, 1, 11),
    ),
  );
  EitherResponseOrException<MyTaskNote> updateNoteResult = Success(
    MyTaskNote(
      id: 'note-1',
      taskId: 'task-1',
      text: 'Updated',
      createdAt: DateTime.utc(2026, 1, 1, 11),
      updatedAt: DateTime.utc(2026, 1, 1, 12),
    ),
  );
  EitherResponseOrException<void> deleteNoteResult = const Success(null);

  MyTaskListRequest? lastFetchTasksRequest;
  bool? lastFetchTasksForceRefresh;
  String? lastUpdateTaskId;
  MyTaskUpdateRequest? lastUpdateRequest;
  String? lastSnoozeTaskId;
  MyTaskSnoozeRequest? lastSnoozeRequest;
  String? lastDeleteTaskId;
  MyTaskCreateRequest? lastCreateRequest;
  int fetchTasksCallCount = 0;

  @override
  Future<EitherResponseOrException<MyTaskPage>> fetchTasks(
    MyTaskListRequest request, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) async {
    fetchTasksCallCount += 1;
    lastFetchTasksRequest = request;
    lastFetchTasksForceRefresh = forceRefresh;

    if (request.page == 2) {
      return fetchTasksPage2Result ??
          const Success(
            MyTaskPage(items: [], totalCount: 1, metrics: MyTaskMetrics.empty),
          );
    }
    return fetchTasksResult;
  }

  @override
  Future<EitherResponseOrException<MyTask>> fetchTask({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  }) async {
    return fetchTaskResult;
  }

  @override
  Future<EitherResponseOrException<MyTask>> createTask(
    MyTaskCreateRequest request, {
    CancelToken? cancelToken,
  }) async {
    lastCreateRequest = request;
    return createTaskResult;
  }

  @override
  Future<EitherResponseOrException<MyTask>> updateTask({
    required String taskId,
    required MyTaskUpdateRequest request,
    CancelToken? cancelToken,
  }) async {
    lastUpdateTaskId = taskId;
    lastUpdateRequest = request;
    return updateTaskResult;
  }

  @override
  Future<EitherResponseOrException<void>> deleteTask({
    required String taskId,
    CancelToken? cancelToken,
  }) async {
    lastDeleteTaskId = taskId;
    return deleteTaskResult;
  }

  @override
  Future<EitherResponseOrException<MyTask>> snoozeTask({
    required String taskId,
    required MyTaskSnoozeRequest request,
    CancelToken? cancelToken,
  }) async {
    lastSnoozeTaskId = taskId;
    lastSnoozeRequest = request;
    return snoozeTaskResult;
  }

  @override
  Future<EitherResponseOrException<List<MyTaskNote>>> fetchNotes({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  }) async {
    return fetchNotesResult;
  }

  @override
  Future<EitherResponseOrException<MyTaskNote>> addNote({
    required String taskId,
    required String note,
    CancelToken? cancelToken,
  }) async {
    return addNoteResult;
  }

  @override
  Future<EitherResponseOrException<MyTaskNote>> updateNote({
    required String taskId,
    required String noteId,
    required String note,
    CancelToken? cancelToken,
  }) async {
    return updateNoteResult;
  }

  @override
  Future<EitherResponseOrException<void>> deleteNote({
    required String taskId,
    required String noteId,
    CancelToken? cancelToken,
  }) async {
    return deleteNoteResult;
  }
}
