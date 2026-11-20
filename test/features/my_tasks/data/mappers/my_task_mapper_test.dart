import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/my_tasks/data/mappers/my_task_mapper.dart';
import 'package:vcare_admin/features/my_tasks/data/models/my_task_model.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_list_request.dart';

void main() {
  group('MyTaskModelMapper', () {
    test('maps API task payload into domain entity', () {
      final model = MyTaskModel.fromJson({
        'id': 'task-1',
        'title': 'Follow up',
        'description': 'Call the client',
        'status': 'IN_PROGRESS',
        'priority': 'URGENT',
        'dueDate': '2030-01-15T15:00:00.000Z',
        'snoozedTill': null,
        'category': 'REFERRAL',
        'categoryReferenceId': 'case-9',
        'clientId': 'client-2',
        'client': {
          'id': 'client-2',
          'name': 'Jane Doe',
          'email': 'jane@example.com',
        },
        'assignedTo': 'user-3',
        'assignee': {
          'id': 'user-3',
          'firstName': 'Alex',
          'lastName': 'Admin',
          'email': 'alex@example.com',
        },
        'createdBy': 'user-1',
        'creator': {'id': 'user-1', 'firstName': 'Sam', 'lastName': 'Creator'},
        'createdAt': '2026-01-01T10:00:00.000Z',
        'updatedAt': '2026-01-02T10:00:00.000Z',
      });

      final entity = model.toEntity();

      expect(entity.id, 'task-1');
      expect(entity.title, 'Follow up');
      expect(entity.status, MyTaskStatus.inProgress);
      expect(entity.priority, MyTaskPriority.urgent);
      expect(entity.category, MyTaskCategory.referralCase);
      expect(entity.client?.name, 'Jane Doe');
      expect(entity.assignee?.displayName, 'Alex Admin');
      expect(entity.createdBy?.displayName, 'Sam Creator');
      expect(entity.origin, MyTaskOrigin.custom);
      expect(entity.isEditable, isTrue);
    });

    test('treats missing createdBy as system origin', () {
      final model = MyTaskModel.fromJson({
        'id': 'task-2',
        'title': 'System task',
        'status': 'TODO',
        'priority': 'MEDIUM',
        'createdAt': '2026-01-01T10:00:00.000Z',
      });

      expect(model.toEntity().origin, MyTaskOrigin.system);
    });
  });

  group('buildMyTaskListRequest', () {
    test('defaults to assigned-to-me open queue', () {
      final request = buildMyTaskListRequest(
        page: 1,
        limit: 25,
        currentUserId: 'me-1',
        ownerFilter: MyTaskOwnerFilter.me,
        quickFilters: {},
        statusFilter: MyTaskStatus.toDo,
        priorityFilter: null,
        categoryFilter: MyTaskQueueCategoryFilter.all,
        originFilter: null,
        search: null,
      );

      expect(request.assignedToUser, 'me-1');
      expect(request.status, MyTaskStatus.toDo);
      expect(request.type, isNull);
      expect(request.toQueryParameters()['status'], 'TODO');
      expect(request.toQueryParameters()['assignedToUser'], 'me-1');
    });

    test('maps overdue and snoozed quick filters', () {
      final overdue = buildMyTaskListRequest(
        page: 1,
        limit: 25,
        currentUserId: 'me-1',
        ownerFilter: MyTaskOwnerFilter.me,
        quickFilters: {MyTaskQuickFilter.overdue},
        statusFilter: MyTaskStatus.toDo,
        priorityFilter: null,
        categoryFilter: MyTaskQueueCategoryFilter.all,
        originFilter: null,
        search: 'billing',
      );

      expect(overdue.type, MyTaskListType.overdue);
      expect(overdue.search, 'billing');

      final snoozed = buildMyTaskListRequest(
        page: 1,
        limit: 25,
        currentUserId: 'me-1',
        ownerFilter: MyTaskOwnerFilter.me,
        quickFilters: {MyTaskQuickFilter.snoozed},
        statusFilter: MyTaskStatus.toDo,
        priorityFilter: null,
        categoryFilter: MyTaskQueueCategoryFilter.payment,
        originFilter: MyTaskOrigin.custom,
        search: null,
      );

      expect(snoozed.snooze, isTrue);
      expect(snoozed.status, isNull);
      expect(snoozed.category, 'Payment Transaction');
      expect(snoozed.origin, MyTaskOrigin.custom);
    });
  });
}
