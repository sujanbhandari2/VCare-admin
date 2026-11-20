import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/config/api_endpoints.dart';
import 'package:vcare_admin/core/services/network/api_client.dart';
import 'package:vcare_admin/core/services/network/models/request_body.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/my_tasks/data/repositories/my_task_repository_impl.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_mutations.dart';
import 'package:vcare_admin/shared/pagination/paginated_response_parser.dart';

class _FakeApiClient implements ApiClient {
  Response<dynamic>? getResponse;
  Response<dynamic>? postResponse;
  Response<dynamic>? patchResponse;
  Response<dynamic>? deleteResponse;

  String? lastGetPath;
  String? lastPostPath;
  String? lastPatchPath;
  String? lastDeletePath;
  Map<String, dynamic>? lastQueryParameters;
  RequestBody? lastPostBody;
  RequestBody? lastPatchBody;
  bool? lastGetAuthenticated;
  bool? lastPostAuthenticated;
  bool? lastPatchAuthenticated;
  bool? lastDeleteAuthenticated;

  @override
  String get baseUrl => 'https://example.com/api/v1/';

  @override
  Map<String, String> get headers => const {};

  @override
  Future<Response<dynamic>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    void Function(int count, int total)? onReceiveProgress,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<Response<dynamic>> delete(
    String path, {
    RequestBody? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) async {
    lastDeletePath = path;
    lastDeleteAuthenticated = isAuthenticated;
    return deleteResponse!;
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    bool forceRefresh = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    lastQueryParameters = queryParameters;
    lastGetAuthenticated = isAuthenticated;
    return getResponse!;
  }

  @override
  Future<Response<dynamic>> post(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = false,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    lastPostAuthenticated = isAuthenticated;
    return postResponse!;
  }

  @override
  Future<Response<dynamic>> patch(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    lastPatchPath = path;
    lastPatchBody = body;
    lastPatchAuthenticated = isAuthenticated;
    return patchResponse!;
  }

  @override
  Future<Response<dynamic>> put(
    String path,
    RequestBody body, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    bool isAuthenticated = true,
    String? customBaseUrl,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) => throw UnimplementedError();
}

Map<String, dynamic> _taskJson({
  String id = 'task-1',
  String title = 'Follow up',
  String status = 'TODO',
}) {
  return {
    'id': id,
    'title': title,
    'status': status,
    'priority': 'MEDIUM',
    'createdAt': '2026-01-01T10:00:00.000Z',
  };
}

void main() {
  group('MyTaskRepositoryImpl', () {
    late _FakeApiClient apiClient;
    late MyTaskRepositoryImpl repository;

    setUp(() {
      apiClient = _FakeApiClient();
      repository = MyTaskRepositoryImpl(apiClient);
    });

    test('fetchTasks hits /tasks with query and metrics', () async {
      apiClient.getResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.tasks),
        statusCode: 200,
        data: [_taskJson()],
        extra: {
          PaginatedResponseParser.paginationExtraKey: {
            'page': 1,
            'limit': 25,
            'total': 1,
            'totalPages': 1,
            'hasNext': false,
            'hasPrev': false,
          },
          PaginatedResponseParser.metricsExtraKey: {
            'open': 1,
            'overdue': 2,
            'dueSoon': 3,
          },
        },
      );

      final result = await repository.fetchTasks(
        const MyTaskListRequest(
          page: 1,
          limit: 25,
          assignedToUser: 'me-1',
          status: MyTaskStatus.toDo,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastGetPath, ApiEndpoints.tasks);
      expect(apiClient.lastGetAuthenticated, isTrue);
      expect(apiClient.lastQueryParameters?['assignedToUser'], 'me-1');
      expect(apiClient.lastQueryParameters?['status'], 'TODO');
      result.when(
        success: (page) {
          expect(page.items, hasLength(1));
          expect(page.totalCount, 1);
          expect(page.metrics.overdue, 2);
        },
        failure: (_) => fail('expected success'),
      );
    });

    test('createTask posts to /tasks', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.tasks),
        statusCode: 200,
        data: _taskJson(title: 'New task'),
      );

      final result = await repository.createTask(
        const MyTaskCreateRequest(title: 'New task'),
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPostPath, ApiEndpoints.tasks);
      expect(apiClient.lastPostAuthenticated, isTrue);
      expect(
        (apiClient.lastPostBody as JsonRequestBody).data['title'],
        'New task',
      );
    });

    test('updateTask patches /tasks/:id', () async {
      apiClient.patchResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.task('task-1')),
        statusCode: 200,
        data: _taskJson(status: 'DONE'),
      );

      final result = await repository.updateTask(
        taskId: 'task-1',
        request: const MyTaskUpdateRequest(status: MyTaskStatus.done),
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPatchPath, ApiEndpoints.task('task-1'));
      expect(
        (apiClient.lastPatchBody as JsonRequestBody).data['status'],
        'DONE',
      );
    });

    test('deleteTask deletes /tasks/:id', () async {
      apiClient.deleteResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.task('task-1')),
        statusCode: 200,
        data: null,
      );

      final result = await repository.deleteTask(taskId: 'task-1');

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastDeletePath, ApiEndpoints.task('task-1'));
      expect(apiClient.lastDeleteAuthenticated, isTrue);
    });

    test('snoozeTask patches snooze endpoint', () async {
      apiClient.patchResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.taskSnooze('task-1')),
        statusCode: 200,
        data: _taskJson(),
      );

      final result = await repository.snoozeTask(
        taskId: 'task-1',
        request: const MyTaskSnoozeRequest(
          snoozedTillIso: '2026-02-01T09:00:00.000Z',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPatchPath, ApiEndpoints.taskSnooze('task-1'));
      expect(
        (apiClient.lastPatchBody as JsonRequestBody).data['snoozedTill'],
        '2026-02-01T09:00:00.000Z',
      );
    });

    test('addNote posts to notes collection', () async {
      apiClient.postResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.taskNotes('task-1')),
        statusCode: 200,
        data: {
          'id': 'note-1',
          'taskId': 'task-1',
          'note': 'Hello',
          'createdAt': '2026-01-01T11:00:00.000Z',
          'updatedAt': '2026-01-01T11:00:00.000Z',
        },
      );

      final result = await repository.addNote(taskId: 'task-1', note: 'Hello');

      expect(result.isSuccess, isTrue);
      expect(apiClient.lastPostPath, ApiEndpoints.taskNotes('task-1'));
      expect((apiClient.lastPostBody as JsonRequestBody).data['note'], 'Hello');
    });

    test('deleteNote deletes note endpoint', () async {
      apiClient.deleteResponse = Response<dynamic>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.taskNote('task-1', 'note-1'),
        ),
        statusCode: 200,
        data: null,
      );

      final result = await repository.deleteNote(
        taskId: 'task-1',
        noteId: 'note-1',
      );

      expect(result.isSuccess, isTrue);
      expect(
        apiClient.lastDeletePath,
        ApiEndpoints.taskNote('task-1', 'note-1'),
      );
    });
  });
}
