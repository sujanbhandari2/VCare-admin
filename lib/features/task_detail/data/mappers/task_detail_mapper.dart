import 'package:vcare_admin/features/task_detail/data/models/task_detail_model.dart';
import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';

extension TaskDetailModelMapper on TaskDetailModel {
  TaskDetail toEntity() {
    return TaskDetail(
      id: id,
      title: title,
      status: TaskDetailStatus.fromApi(status),
      priority: TaskDetailPriority.fromApi(priority),
      linkKind: TaskDetailLinkKind.fromApi(category),
      description: description,
      dueDate: _parseDate(dueDate),
      apiCategory: category,
      linkedReferenceId: categoryReferenceId,
      linkedReferenceLabel: categoryReferenceLabel,
      clientId: clientId,
      assignee: _person(assignee, assignedTo),
      createdBy: _person(creator, createdBy),
      createdAt: _parseDate(createdAt),
      updatedAt: _parseDate(updatedAt),
    );
  }
}

/// API timestamps are UTC; the sheet renders them on the device's clock.
DateTime? _parseDate(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return DateTime.tryParse(trimmed)?.toLocal();
}

TaskDetailPerson? _person(TaskDetailPersonModel? model, String? fallbackId) {
  final id = model?.id?.trim() ?? fallbackId?.trim() ?? '';
  final name = model?.fullName?.trim() ?? model?.email?.trim();

  if (id.isEmpty && (name == null || name.isEmpty)) return null;
  return TaskDetailPerson(id: id, name: name);
}
