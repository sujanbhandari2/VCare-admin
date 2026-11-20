import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_page.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_task_repository_provider.dart';
import 'package:vcare_admin/features/my_tasks/presentation/providers/my_tasks_list_state_provider.dart';
import 'package:vcare_admin/shared/network/network_fetch_session_provider.dart';

import '../../../../fixtures/repositories/fake_my_task_repository.dart';

const _sessionUser = AdminAuthUser(
  id: 'me-1',
  email: 'me@example.com',
  firstName: 'Me',
  lastName: 'User',
  currentTenant: AdminAuthTenant(id: 't1', slug: 'acme', name: 'Acme'),
  currentRoles: ['admin'],
);

void main() {
  group('MyTasksListStateNotifier', () {
    late FakeMyTaskRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = FakeMyTaskRepository();
      container = ProviderContainer(
        overrides: [
          myTaskRepositoryProvider.overrideWithValue(repository),
          adminAuthSessionProvider.overrideWithValue(
            const AdminAuthSessionState(
              accessToken: 'token',
              user: _sessionUser,
              menu: ['tasks'],
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('defaults to assigned-to-me open queue', () async {
      await container.read(myTasksListStateProvider.notifier).loadInitial();

      final state = container.read(myTasksListStateProvider);
      expect(state.ownerFilter, MyTaskOwnerFilter.me);
      expect(state.statusFilter, MyTaskStatus.toDo);
      expect(state.items, hasLength(1));
      expect(repository.lastFetchTasksRequest?.assignedToUser, 'me-1');
      expect(repository.lastFetchTasksRequest?.status, MyTaskStatus.toDo);
      expect(repository.lastFetchTasksForceRefresh, isTrue);
    });

    test('uses cache after session is hydrated', () async {
      container
          .read(networkFetchSessionProvider.notifier)
          .markSessionHydrated();

      await container.read(myTasksListStateProvider.notifier).loadInitial();

      expect(repository.lastFetchTasksForceRefresh, isFalse);
    });

    test('search trims query and reloads', () async {
      await container.read(myTasksListStateProvider.notifier).search('  jane ');

      expect(container.read(myTasksListStateProvider).searchQuery, 'jane');
      expect(repository.lastFetchTasksRequest?.search, 'jane');
      expect(repository.lastFetchTasksForceRefresh, isTrue);
    });

    test('toggle overdue quick filter maps type=OVERDUE', () async {
      await container
          .read(myTasksListStateProvider.notifier)
          .toggleQuickFilter(MyTaskQuickFilter.overdue);

      expect(
        container.read(myTasksListStateProvider).hasOverdueQuickFilter,
        isTrue,
      );
      expect(repository.lastFetchTasksRequest?.type, MyTaskListType.overdue);
    });

    test('toggle snoozed clears overdue and sets snooze=true', () async {
      final notifier = container.read(myTasksListStateProvider.notifier);
      await notifier.toggleQuickFilter(MyTaskQuickFilter.overdue);
      await notifier.toggleQuickFilter(MyTaskQuickFilter.snoozed);

      final state = container.read(myTasksListStateProvider);
      expect(state.hasSnoozedQuickFilter, isTrue);
      expect(state.hasOverdueQuickFilter, isFalse);
      expect(repository.lastFetchTasksRequest?.snooze, isTrue);
      expect(repository.lastFetchTasksRequest?.status, isNull);
    });

    test('loadMore appends next page', () async {
      repository.fetchTasksResult = Success(
        MyTaskPage(
          items: [sampleMyTask(id: 'task-1')],
          totalCount: 2,
          metrics: const MyTaskMetrics(open: 2),
        ),
      );
      repository.fetchTasksPage2Result = Success(
        MyTaskPage(
          items: [sampleMyTask(id: 'task-2', title: 'Second')],
          totalCount: 2,
          metrics: const MyTaskMetrics(open: 2),
        ),
      );

      await container.read(myTasksListStateProvider.notifier).loadInitial();
      await container.read(myTasksListStateProvider.notifier).loadMore();

      final state = container.read(myTasksListStateProvider);
      expect(state.items.map((t) => t.id), ['task-1', 'task-2']);
      expect(state.hasMore, isFalse);
    });

    test('loadInitial failure stores error', () async {
      repository.fetchTasksResult = Failure(
        HttpException(
          message: 'Unable to load tasks',
          errorType: HttpErrorType.client,
        ),
      );

      await container.read(myTasksListStateProvider.notifier).loadInitial();

      final state = container.read(myTasksListStateProvider);
      expect(state.isInitialError, isTrue);
      expect(state.errorMessage, 'Unable to load tasks');
    });

    test('refresh forces network refresh', () async {
      container
          .read(networkFetchSessionProvider.notifier)
          .markSessionHydrated();
      await container.read(myTasksListStateProvider.notifier).loadInitial();
      expect(repository.lastFetchTasksForceRefresh, isFalse);

      await container.read(myTasksListStateProvider.notifier).refresh();

      expect(repository.lastFetchTasksForceRefresh, isTrue);
      expect(repository.lastFetchTasksRequest?.page, 1);
    });
  });
}
