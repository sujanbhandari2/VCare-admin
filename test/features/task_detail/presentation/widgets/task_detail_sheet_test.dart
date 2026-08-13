import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/task_detail/domain/repositories/task_detail_repository.dart';
import 'package:vcare_admin/features/task_detail/presentation/providers/task_detail_repository_provider.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_sheet.dart';
import 'package:vcare_admin/features/task_detail/presentation/widgets/task_detail_skeleton.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';
import 'package:vcare_admin/features/users/domain/repositories/internal_users_repository.dart';
import 'package:vcare_admin/features/users/presentation/providers/internal_users_repository_provider.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';

class _FakeTaskDetailRepository implements TaskDetailRepository {
  _FakeTaskDetailRepository(this.result);

  EitherResponseOrException<TaskDetail> result;
  Future<void>? delay;
  int calls = 0;

  int updateCalls = 0;
  String? lastTitle;
  String? lastDescription;
  String? lastAssignedTo;
  String? lastDueDateIso;
  TaskDetailStatus? lastStatus;
  TaskDetailPriority? lastPriority;
  String? lastCategory;
  String? lastCategoryReferenceId;

  @override
  Future<EitherResponseOrException<TaskDetail>> fetchTaskDetail({
    required String taskId,
    CancelToken? cancelToken,
    bool forceRefresh = true,
  }) async {
    calls += 1;
    if (delay != null) await delay;
    return result;
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
  }) async {
    updateCalls += 1;
    lastTitle = title;
    lastDescription = description;
    lastAssignedTo = assignedTo;
    lastDueDateIso = dueDateIso;
    lastStatus = status;
    lastPriority = priority;
    lastCategory = category;
    lastCategoryReferenceId = categoryReferenceId;

    final updated = _task(status: status, priority: priority, title: title);
    result = Success(updated);
    return Success(updated);
  }
}

class _FakeInternalUsersRepository implements InternalUsersRepository {
  _FakeInternalUsersRepository([this.users = const []]);

  final List<AssociatedUser> users;
  int calls = 0;

  @override
  Future<EitherResponseOrException<List<AssociatedUser>>> fetchInternalUsers({
    int page = 1,
    int limit = 100,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    calls += 1;
    return Success(users);
  }
}

AssociatedUser _user({
  required String id,
  String? firstName,
  String? lastName,
  String email = '',
}) {
  return AssociatedUser(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    userType: 'PLATFORM_USER',
    role: 'ADMIN',
    status: 'ACTIVE',
  );
}

TaskDetail _task({
  TaskDetailStatus status = TaskDetailStatus.inProgress,
  TaskDetailPriority priority = TaskDetailPriority.medium,
  String title = 'Membership follow-up: New Couple Offering',
  TaskDetailPerson? assignee = const TaskDetailPerson(
    id: 'user-1',
    name: 'VCARE ADVOCACY PLATFORM ADMIN LLC',
  ),
}) {
  return TaskDetail(
    id: 'task-1',
    title: title,
    description: 'MEMBERSHIP TASK FROM THE MEMBERSHIP MODULE',
    status: status,
    priority: priority,
    linkKind: TaskDetailLinkKind.membership,
    apiCategory: 'ENROLLMENT',
    linkedReferenceId: '26ede588-2db1-444b',
    dueDate: DateTime(2026, 7, 14, 3),
    assignee: assignee,
    createdBy: const TaskDetailPerson(
      id: 'user-1',
      name: 'VCARE ADVOCACY PLATFORM ADMIN LLC',
    ),
  );
}

void main() {
  Widget wrap(
    _FakeTaskDetailRepository repository, {
    bool startInEditMode = false,
    VoidCallback? onSaved,
    InternalUsersRepository? usersRepository,
  }) {
    return ProviderScope(
      overrides: [
        taskDetailRepositoryProvider.overrideWith((ref) => repository),
        internalUsersRepositoryProvider.overrideWith(
          (ref) => usersRepository ?? _FakeInternalUsersRepository(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [VCareThemeExtension.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TaskDetailSheet(
            taskId: 'task-1',
            startInEditMode: startInEditMode,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  }

  group('TaskDetailSheet', () {
    testWidgets('shimmers the fields while the task loads', (tester) async {
      final gate = Completer<void>();
      final repository = _FakeTaskDetailRepository(Success(_task()))
        ..delay = gate.future;

      await tester.pumpWidget(wrap(repository));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TaskDetailSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.text('View Task'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(Shimmer), findsNothing);
    });

    testWidgets('renders the task fields read-only', (tester) async {
      await tester.pumpWidget(wrap(_FakeTaskDetailRepository(Success(_task()))));
      await tester.pumpAndSettle();

      expect(find.text('View Task'), findsOneWidget);
      expect(find.text('Review task details and progress.'), findsOneWidget);
      expect(find.text('TITLE'), findsOneWidget);
      expect(
        find.text('Membership follow-up: New Couple Offering'),
        findsOneWidget,
      );
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('MEMBERSHIP'), findsOneWidget);
      expect(find.text('26ede588-2db1-444b'), findsOneWidget);
      expect(find.text('ASSIGNED TO'), findsOneWidget);
      expect(find.text('DUE DATE & TIME'), findsOneWidget);
      expect(find.text('07/14/2026 03:00 AM'), findsOneWidget);
      expect(find.text('PRIORITY'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(
        find.text('Created by VCARE ADVOCACY PLATFORM ADMIN LLC'),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('resolves the assignee name from team members', (tester) async {
      final repository = _FakeTaskDetailRepository(
        Success(_task(assignee: const TaskDetailPerson(id: 'user-7'))),
      );
      final users = _FakeInternalUsersRepository([
        _user(id: 'user-7', firstName: 'Jane', lastName: 'Doe'),
      ]);

      await tester.pumpWidget(wrap(repository, usersRepository: users));
      await tester.pumpAndSettle();

      expect(users.calls, 1);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('user-7'), findsNothing);
    });

    testWidgets('falls back to Unassigned for unknown users', (tester) async {
      final repository = _FakeTaskDetailRepository(
        Success(_task(assignee: const TaskDetailPerson(id: 'user-404'))),
      );

      await tester.pumpWidget(wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('user-404'), findsNothing);
    });

    testWidgets('retries after a failure', (tester) async {
      final repository = _FakeTaskDetailRepository(
        Failure(
          HttpException(
            title: 'Error',
            message: 'Boom',
            errorType: HttpErrorType.client,
          ),
        ),
      );

      await tester.pumpWidget(wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load task'), findsOneWidget);
      expect(repository.calls, 1);

      repository.result = Success(_task());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.calls, 2);
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('edits and saves a task', (tester) async {
      final repository = _FakeTaskDetailRepository(Success(_task()));
      var savedCallbacks = 0;

      await tester.pumpWidget(
        wrap(repository, onSaved: () => savedCallbacks += 1),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Update task details and assignment.'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // The membership link stays read-only while editing.
      expect(find.text('MEMBERSHIP'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Updated title');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(repository.lastTitle, 'Updated title');
      expect(repository.lastAssignedTo, 'user-1');
      expect(repository.lastStatus, TaskDetailStatus.inProgress);
      expect(repository.lastPriority, TaskDetailPriority.medium);
      // The locked link is preserved instead of being cleared.
      expect(repository.lastCategory, 'ENROLLMENT');
      expect(repository.lastCategoryReferenceId, '26ede588-2db1-444b');
      expect(savedCallbacks, 1);
      // Saving returns to the read-only view with the fresh values.
      expect(find.text('View Task'), findsOneWidget);
      expect(find.text('Updated title'), findsOneWidget);
    });

    testWidgets('opens directly in edit mode when asked', (tester) async {
      final repository = _FakeTaskDetailRepository(Success(_task()));

      await tester.pumpWidget(wrap(repository, startInEditMode: true));
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('hides Edit for completed tasks', (tester) async {
      final repository = _FakeTaskDetailRepository(
        Success(_task(status: TaskDetailStatus.done)),
      );

      await tester.pumpWidget(wrap(repository));
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
