import 'package:vcare_admin/shared/models/loadable_list_item.dart';

/// Task status — mirrors web queue `WorkStatus` + API `ApiTaskStatus`.
enum MyTaskStatus {
  toDo,
  inProgress,
  done,
  cancelled;

  String get label => switch (this) {
    MyTaskStatus.toDo => 'Open',
    MyTaskStatus.inProgress => 'In Progress',
    MyTaskStatus.done => 'Completed',
    MyTaskStatus.cancelled => 'Cancelled',
  };

  String get apiValue => switch (this) {
    MyTaskStatus.toDo => 'TODO',
    MyTaskStatus.inProgress => 'IN_PROGRESS',
    MyTaskStatus.done => 'DONE',
    MyTaskStatus.cancelled => 'CANCELLED',
  };

  bool get isTerminal =>
      this == MyTaskStatus.done || this == MyTaskStatus.cancelled;

  static const List<MyTaskStatus> editableValues = [
    MyTaskStatus.toDo,
    MyTaskStatus.inProgress,
    MyTaskStatus.done,
  ];

  static MyTaskStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'IN_PROGRESS':
        return MyTaskStatus.inProgress;
      case 'DONE':
      case 'COMPLETED':
        return MyTaskStatus.done;
      case 'CANCELLED':
      case 'CANCELED':
        return MyTaskStatus.cancelled;
      case 'TODO':
      case 'NEW':
      case 'REMINDED':
      case 'SNOOZED':
      default:
        return MyTaskStatus.toDo;
    }
  }
}

/// Task priority — mirrors web `TaskPriority` / API `ApiTaskPriority`.
enum MyTaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
    MyTaskPriority.low => 'Low',
    MyTaskPriority.medium => 'Medium',
    MyTaskPriority.high => 'High',
    MyTaskPriority.urgent => 'Urgent',
  };

  String get apiValue => switch (this) {
    MyTaskPriority.low => 'LOW',
    MyTaskPriority.medium => 'MEDIUM',
    MyTaskPriority.high => 'HIGH',
    MyTaskPriority.urgent => 'URGENT',
  };

  /// Queue filter chip label (web uses high/normal/low).
  String get filterLabel => switch (this) {
    MyTaskPriority.low => 'Low',
    MyTaskPriority.medium => 'Medium',
    MyTaskPriority.high || MyTaskPriority.urgent => 'High Priority',
  };

  static MyTaskPriority fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'LOW':
        return MyTaskPriority.low;
      case 'HIGH':
        return MyTaskPriority.high;
      case 'URGENT':
        return MyTaskPriority.urgent;
      case 'MEDIUM':
      default:
        return MyTaskPriority.medium;
    }
  }
}

/// UI category — mirrors web `TaskCategory`.
enum MyTaskCategory {
  referralCase,
  membershipCase,
  clientCase,
  billingCase,
  careCoordination;

  String get label => switch (this) {
    MyTaskCategory.referralCase => 'Referral case',
    MyTaskCategory.membershipCase => 'Membership case',
    MyTaskCategory.clientCase => 'Client case',
    MyTaskCategory.billingCase => 'Billing case',
    MyTaskCategory.careCoordination => 'Care coordination',
  };

  String get apiValue => switch (this) {
    MyTaskCategory.referralCase => 'REFERRAL',
    MyTaskCategory.membershipCase => 'ENROLLMENT',
    MyTaskCategory.clientCase => 'CLIENT',
    MyTaskCategory.billingCase => 'Payment Transaction',
    MyTaskCategory.careCoordination => 'CARE_COORDINATION',
  };

  static MyTaskCategory? fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'REFERRAL':
      case 'REFERRAL CASE':
        return MyTaskCategory.referralCase;
      case 'ENROLLMENT':
        return MyTaskCategory.membershipCase;
      case 'CLIENT':
        return MyTaskCategory.clientCase;
      case 'BILLING':
      case 'PAYMENT TRANSACTION':
        return MyTaskCategory.billingCase;
      case 'CARE_COORDINATION':
      case 'SERVICE':
        return MyTaskCategory.careCoordination;
      default:
        return null;
    }
  }
}

/// System vs custom origin — mirrors web `TaskOrigin`.
enum MyTaskOrigin {
  system,
  custom;

  String get label => switch (this) {
    MyTaskOrigin.system => 'System',
    MyTaskOrigin.custom => 'Custom',
  };

  String get apiValue => switch (this) {
    MyTaskOrigin.system => 'SYSTEM',
    MyTaskOrigin.custom => 'CUSTOM',
  };
}

/// List tab / metrics type — mirrors web `ApiTaskType`.
enum MyTaskListType {
  open,
  overdue,
  dueSoon;

  String get apiValue => switch (this) {
    MyTaskListType.open => 'OPEN',
    MyTaskListType.overdue => 'OVERDUE',
    MyTaskListType.dueSoon => 'DUE_SOON',
  };
}

/// Person attached to a task (assignee / creator).
class MyTaskPerson {
  const MyTaskPerson({
    required this.id,
    this.name,
    this.email,
    this.isInactive = false,
  });

  final String id;
  final String? name;
  final String? email;
  final bool isInactive;

  String get displayName {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail;
    return id;
  }
}

/// Linked client summary from the task payload.
class MyTaskClient {
  const MyTaskClient({
    required this.id,
    required this.name,
    this.email,
    this.clientType,
    this.groupName,
  });

  final String id;
  final String name;
  final String? email;
  final String? clientType;
  final String? groupName;
}

/// A single task from `GET /tasks` — the My Tasks queue row.
class MyTask implements LoadableListItem {
  const MyTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.description,
    this.category,
    this.apiCategory,
    this.clientId,
    this.client,
    this.clientName,
    this.categoryReferenceId,
    this.assignee,
    this.createdBy,
    this.snoozedTill,
    this.dueDate,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final MyTaskStatus status;
  final MyTaskPriority priority;
  final MyTaskCategory? category;
  final String? apiCategory;
  final String? clientId;
  final MyTaskClient? client;
  final String? clientName;
  final String? categoryReferenceId;
  final MyTaskPerson? assignee;
  final MyTaskPerson? createdBy;
  final DateTime? snoozedTill;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MyTaskOrigin get origin =>
      createdBy == null ? MyTaskOrigin.system : MyTaskOrigin.custom;

  String get displayClientName {
    final fromClient = client?.name.trim();
    if (fromClient != null && fromClient.isNotEmpty) return fromClient;
    final fallback = clientName?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return 'No client';
  }

  String get displayAssigneeName =>
      assignee?.displayName.trim().isNotEmpty == true
      ? assignee!.displayName
      : 'Unassigned';

  bool get isSnoozed {
    final until = snoozedTill;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  bool get isOverdue {
    if (status.isTerminal) return false;
    final due = dueDate;
    if (due == null) return false;
    return due.isBefore(DateTime.now());
  }

  bool get isEditable => status != MyTaskStatus.done;

  MyTask copyWith({
    String? id,
    String? title,
    String? description,
    MyTaskStatus? status,
    MyTaskPriority? priority,
    MyTaskCategory? category,
    String? apiCategory,
    String? clientId,
    MyTaskClient? client,
    String? clientName,
    String? categoryReferenceId,
    MyTaskPerson? assignee,
    MyTaskPerson? createdBy,
    DateTime? snoozedTill,
    bool clearSnoozedTill = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      apiCategory: apiCategory ?? this.apiCategory,
      clientId: clientId ?? this.clientId,
      client: client ?? this.client,
      clientName: clientName ?? this.clientName,
      categoryReferenceId: categoryReferenceId ?? this.categoryReferenceId,
      assignee: assignee ?? this.assignee,
      createdBy: createdBy ?? this.createdBy,
      snoozedTill: clearSnoozedTill ? null : (snoozedTill ?? this.snoozedTill),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
