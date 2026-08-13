/// Task status for case-linked tasks (UI values).
enum CaseTaskStatus {
  submitted,
  inProgress,
  completed,
  cancelled;

  String get apiValue => switch (this) {
    CaseTaskStatus.submitted => 'NEW',
    CaseTaskStatus.inProgress => 'IN_PROGRESS',
    CaseTaskStatus.completed => 'COMPLETED',
    CaseTaskStatus.cancelled => 'CANCELLED',
  };

  String get label => switch (this) {
    CaseTaskStatus.submitted => 'Submitted',
    CaseTaskStatus.inProgress => 'In Progress',
    CaseTaskStatus.completed => 'Completed',
    CaseTaskStatus.cancelled => 'Cancelled',
  };

  static CaseTaskStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'IN_PROGRESS':
        return CaseTaskStatus.inProgress;
      case 'COMPLETED':
        return CaseTaskStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return CaseTaskStatus.cancelled;
      case 'NEW':
      case 'SUBMITTED':
      default:
        return CaseTaskStatus.submitted;
    }
  }
}

/// A task linked to a referral case.
class CaseTask {
  const CaseTask({
    required this.id,
    required this.title,
    required this.status,
    this.completed = false,
    this.assignee = '',
    this.assigneeId,
    this.dueDate,
    this.description = '',
    this.priority,
  });

  final String id;
  final String title;
  final bool completed;
  final CaseTaskStatus status;
  final String assignee;
  final String? assigneeId;
  final String? dueDate;
  final String description;
  final String? priority;

  CaseTask copyWith({
    String? id,
    String? title,
    bool? completed,
    CaseTaskStatus? status,
    String? assignee,
    String? assigneeId,
    String? dueDate,
    String? description,
    String? priority,
  }) {
    return CaseTask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      priority: priority ?? this.priority,
    );
  }
}
