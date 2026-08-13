import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/task_detail/data/mappers/task_detail_mapper.dart';
import 'package:vcare_admin/features/task_detail/data/models/task_detail_model.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';

void main() {
  group('TaskDetailModelMapper', () {
    test('maps an enrollment task with a nested assignee', () {
      final entity = TaskDetailModel.fromJson({
        'id': 'task-1',
        'title': 'Membership follow-up: New Couple Offering',
        'description': 'MEMBERSHIP TASK FROM THE MEMBERSHIP MODULE',
        'status': 'IN_PROGRESS',
        'priority': 'MEDIUM',
        'dueDate': '2026-07-14T09:00:00.000Z',
        'category': 'ENROLLMENT',
        'categoryReferenceId': '26ede588-2d b1',
        'assignee': {
          'firstName': 'Vcare',
          'lastName': 'Admin',
          'id': 'user-1',
        },
        'createdBy': 'user-1',
        'createdAt': '2026-07-01T09:00:00.000Z',
      }).toEntity();

      expect(entity.id, 'task-1');
      expect(entity.status, TaskDetailStatus.inProgress);
      expect(entity.priority, TaskDetailPriority.medium);
      expect(entity.linkKind, TaskDetailLinkKind.membership);
      expect(entity.linkKind.label, 'Membership');
      expect(entity.hasLinkedRecord, isTrue);
      expect(entity.assignee?.id, 'user-1');
      expect(entity.assignee?.name, 'Vcare Admin');
      expect(entity.isEditable, isTrue);
      expect(entity.dueDate?.isUtc, isFalse);
      expect(
        entity.dueDate?.toUtc(),
        DateTime.utc(2026, 7, 14, 9),
      );
    });

    test('keeps bare user ids so names can be resolved later', () {
      final entity = TaskDetailModel.fromJson({
        'id': 'task-2',
        'title': 'Call the client',
        'assignedTo': 'user-42',
        'createdBy': 'user-99',
      }).toEntity();

      expect(entity.assignee?.id, 'user-42');
      expect(entity.assignee?.name, isNull);
      expect(entity.createdBy?.id, 'user-99');
      expect(entity.createdBy?.name, isNull);
    });

    test('treats general tasks as having no linked record', () {
      final entity = TaskDetailModel.fromJson({
        'id': 'task-3',
        'title': 'Internal cleanup',
        'category': 'GENERAL',
        'categoryReferenceId': 'ref-1',
        'status': 'DONE',
      }).toEntity();

      expect(entity.linkKind, TaskDetailLinkKind.general);
      expect(entity.hasLinkedRecord, isFalse);
      expect(entity.status, TaskDetailStatus.done);
      expect(entity.isEditable, isFalse);
    });

    test('defaults missing status and priority like the web drawer', () {
      final entity = TaskDetailModel.fromJson({
        'id': 'task-4',
        'title': 'No metadata',
      }).toEntity();

      expect(entity.status, TaskDetailStatus.toDo);
      expect(entity.status.label, 'To do');
      expect(entity.priority, TaskDetailPriority.medium);
      expect(entity.dueDate, isNull);
      expect(entity.assignee, isNull);
    });
  });
}
