/// Task status — labels match the web task drawer `STATUS_OPTIONS`.
enum TaskDetailStatus {
  toDo,
  inProgress,
  done,
  cancelled;

  String get label => switch (this) {
    TaskDetailStatus.toDo => 'To do',
    TaskDetailStatus.inProgress => 'In Progress',
    TaskDetailStatus.done => 'Done',
    TaskDetailStatus.cancelled => 'Cancelled',
  };

  String get apiValue => switch (this) {
    TaskDetailStatus.toDo => 'TODO',
    TaskDetailStatus.inProgress => 'IN_PROGRESS',
    TaskDetailStatus.done => 'DONE',
    TaskDetailStatus.cancelled => 'CANCELLED',
  };

  /// Statuses offered in the edit form — the web drawer exposes these three.
  static const List<TaskDetailStatus> editableValues = [
    TaskDetailStatus.toDo,
    TaskDetailStatus.inProgress,
    TaskDetailStatus.done,
  ];

  static TaskDetailStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'IN_PROGRESS':
        return TaskDetailStatus.inProgress;
      case 'DONE':
      case 'COMPLETED':
        return TaskDetailStatus.done;
      case 'CANCELLED':
      case 'CANCELED':
        return TaskDetailStatus.cancelled;
      case 'TODO':
      case 'NEW':
      case 'REMINDED':
      default:
        return TaskDetailStatus.toDo;
    }
  }
}

/// Task priority — labels match the web task drawer `PRIORITY_OPTIONS`.
enum TaskDetailPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
    TaskDetailPriority.low => 'Low',
    TaskDetailPriority.medium => 'Medium',
    TaskDetailPriority.high => 'High',
    TaskDetailPriority.urgent => 'Urgent',
  };

  String get apiValue => switch (this) {
    TaskDetailPriority.low => 'LOW',
    TaskDetailPriority.medium => 'MEDIUM',
    TaskDetailPriority.high => 'HIGH',
    TaskDetailPriority.urgent => 'URGENT',
  };

  static TaskDetailPriority fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'LOW':
        return TaskDetailPriority.low;
      case 'HIGH':
        return TaskDetailPriority.high;
      case 'URGENT':
        return TaskDetailPriority.urgent;
      case 'MEDIUM':
      default:
        return TaskDetailPriority.medium;
    }
  }
}

/// Record a task is linked to, derived from the API `category`.
///
/// Mirrors the web `API_CATEGORY_TO_KIND` map, where `GENERAL` tasks carry no
/// linked record.
enum TaskDetailLinkKind {
  client,
  membership,
  billing,
  service,
  referralCase,
  general;

  String get label => switch (this) {
    TaskDetailLinkKind.client => 'Client',
    TaskDetailLinkKind.membership => 'Membership',
    TaskDetailLinkKind.billing => 'Billing',
    TaskDetailLinkKind.service => 'Service',
    TaskDetailLinkKind.referralCase => 'Case',
    TaskDetailLinkKind.general => 'Linked record',
  };

  static TaskDetailLinkKind fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'CLIENT':
        return TaskDetailLinkKind.client;
      case 'ENROLLMENT':
        return TaskDetailLinkKind.membership;
      case 'BILLING':
        return TaskDetailLinkKind.billing;
      case 'SERVICE':
        return TaskDetailLinkKind.service;
      case 'REFERRAL':
        return TaskDetailLinkKind.referralCase;
      case 'GENERAL':
      default:
        return TaskDetailLinkKind.general;
    }
  }
}

/// Person attached to a task. Tasks usually carry only a user id, so the name
/// is resolved against the loaded team members — see
/// `resolveTaskDetailPersonLabel`.
class TaskDetailPerson {
  const TaskDetailPerson({required this.id, this.name});

  final String id;
  final String? name;

  bool get isEmpty => id.trim().isEmpty && (name?.trim().isEmpty ?? true);
}

/// A single task from `GET tasks/:id`, shown read-only in the View Task sheet.
class TaskDetail {
  const TaskDetail({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.linkKind,
    this.description,
    this.dueDate,
    this.apiCategory,
    this.linkedReferenceId,
    this.linkedReferenceLabel,
    this.clientId,
    this.assignee,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final TaskDetailStatus status;
  final TaskDetailPriority priority;
  final TaskDetailLinkKind linkKind;
  final String? description;
  final DateTime? dueDate;

  /// Raw API `category`, kept so updates can preserve the task's link.
  final String? apiCategory;
  final String? linkedReferenceId;
  final String? linkedReferenceLabel;
  final String? clientId;
  final TaskDetailPerson? assignee;
  final TaskDetailPerson? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// `GENERAL` tasks have nothing to link to, and the field is hidden.
  bool get hasLinkedRecord =>
      linkKind != TaskDetailLinkKind.general &&
      (linkedReferenceId?.trim().isNotEmpty ?? false);

  /// Name when the payload carried one, otherwise the raw reference id, which
  /// is what the web drawer shows for membership tasks.
  String get linkedRecordLabel {
    final label = linkedReferenceLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return linkedReferenceId?.trim() ?? '';
  }

  /// The web drawer marks done tasks read-only and hides Edit entirely.
  bool get isEditable => status != TaskDetailStatus.done;
}
