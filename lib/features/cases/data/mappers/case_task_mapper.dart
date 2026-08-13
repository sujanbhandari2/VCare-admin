import 'package:vcare_admin/features/cases/data/models/case_task_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_task.dart';

extension CaseTaskModelMapper on CaseTaskModel {
  CaseTask toEntity() {
    final statusValue = CaseTaskStatus.fromApi(status);
    final assigneeId = assignedTo ?? assignee?.id;

    return CaseTask(
      id: id,
      title: title,
      status: statusValue,
      completed: statusValue == CaseTaskStatus.completed,
      assignee: _resolveAssigneeName(assignee),
      assigneeId: assigneeId,
      dueDate: dueDate,
      description: description ?? '',
      priority: priority,
    );
  }
}

String _resolveAssigneeName(CaseTaskAssigneeModel? assignee) {
  final fullName = assignee?.fullName?.trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;

  final email = assignee?.email?.trim();
  if (email != null && email.isNotEmpty) return email;

  return '';
}
