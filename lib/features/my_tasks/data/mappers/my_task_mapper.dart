import 'package:vcare_admin/features/my_tasks/data/models/my_task_model.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_metrics.dart';
import 'package:vcare_admin/features/my_tasks/domain/entities/my_task_note.dart';

extension MyTaskModelMapper on MyTaskModel {
  MyTask toEntity() {
    return MyTask(
      id: id,
      title: title,
      description: description,
      status: MyTaskStatus.fromApi(status),
      priority: MyTaskPriority.fromApi(priority),
      category: MyTaskCategory.fromApi(category),
      apiCategory: category,
      clientId: clientId ?? client?.id,
      client: client?.toEntity(),
      clientName: clientName,
      categoryReferenceId: categoryReferenceId,
      assignee: _person(assignee, assignedTo),
      createdBy: _person(creator, createdBy),
      snoozedTill: _parseDate(snoozedTill),
      dueDate: _parseDate(dueDate),
      createdAt:
          _parseDate(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _parseDate(updatedAt),
    );
  }
}

extension MyTaskClientModelMapper on MyTaskClientModel {
  MyTaskClient toEntity() {
    return MyTaskClient(
      id: id,
      name: name,
      email: email,
      clientType: clientType,
      groupName: groupName,
    );
  }
}

extension MyTaskMetricsModelMapper on MyTaskMetricsModel {
  MyTaskMetrics toEntity() {
    return MyTaskMetrics(open: open, overdue: overdue, dueSoon: dueSoon);
  }
}

extension MyTaskNoteModelMapper on MyTaskNoteModel {
  MyTaskNote toEntity() {
    final author = creator;
    final parts = (author?.fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final first = parts.isEmpty ? null : parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : null;

    return MyTaskNote(
      id: id,
      taskId: taskId,
      text: note,
      status: MyTaskNoteStatus.fromApi(status),
      authorId: author?.id ?? createdBy,
      authorLabel: author?.fullName ?? author?.email,
      authorFirstName: first,
      authorLastName: last,
      createdAt:
          _parseDate(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDate(updatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

DateTime? _parseDate(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return DateTime.tryParse(trimmed)?.toLocal();
}

MyTaskPerson? _person(MyTaskPersonModel? model, String? fallbackId) {
  final id = model?.id?.trim() ?? fallbackId?.trim() ?? '';
  final name = model?.fullName?.trim() ?? model?.email?.trim();

  if (id.isEmpty && (name == null || name.isEmpty)) return null;
  return MyTaskPerson(
    id: id,
    name: name,
    email: model?.email,
    isInactive: model?.isInactive ?? false,
  );
}
