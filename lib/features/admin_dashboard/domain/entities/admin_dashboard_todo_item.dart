import 'package:vcare_admin/shared/models/loadable_list_item.dart';

enum AdminDashboardTodoItemType {
  paymentFailed,
  taskOverdue,
  taskDueSoon,
}

enum AdminDashboardTaskPriority {
  low,
  medium,
  high,
  urgent,
}

enum AdminDashboardTaskStatus {
  newTask,
  inProgress,
  completed,
  cancelled,
}

class AdminDashboardTodoResource {
  const AdminDashboardTodoResource({
    required this.type,
    required this.id,
  });

  final String type;
  final String id;
}

class AdminDashboardPaymentDetails {
  const AdminDashboardPaymentDetails({
    this.name,
    this.amount,
    this.currency,
    this.code,
    this.relatedId,
    this.membershipName,
    this.billingStartDate,
    this.billingEndDate,
    this.failureReason,
    this.failureMessage,
    this.failureActionMessage,
  });

  final String? name;
  final String? amount;
  final String? currency;
  final String? code;
  final String? relatedId;
  final String? membershipName;
  final String? billingStartDate;
  final String? billingEndDate;
  final String? failureReason;
  final String? failureMessage;
  final String? failureActionMessage;
}

class AdminDashboardTodoClientPreview {
  const AdminDashboardTodoClientPreview({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

sealed class AdminDashboardTodoItem implements LoadableListItem {
  const AdminDashboardTodoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.resource,
  });

  final String id;
  final String title;
  final String description;
  final DateTime occurredAt;
  final AdminDashboardTodoResource resource;
}

class AdminDashboardFailedPaymentTodoItem extends AdminDashboardTodoItem {
  const AdminDashboardFailedPaymentTodoItem({
    required super.id,
    required super.title,
    required super.description,
    required super.occurredAt,
    required super.resource,
    required this.details,
  });

  final AdminDashboardPaymentDetails details;

  AdminDashboardTodoItemType get type => AdminDashboardTodoItemType.paymentFailed;
}

class AdminDashboardTaskTodoItem extends AdminDashboardTodoItem {
  const AdminDashboardTaskTodoItem({
    required super.id,
    required super.title,
    required super.description,
    required super.occurredAt,
    required super.resource,
    required this.itemType,
    required this.priority,
    required this.status,
    required this.dueDate,
    this.client,
  });

  final AdminDashboardTodoItemType itemType;
  final AdminDashboardTaskPriority priority;
  final AdminDashboardTaskStatus status;
  final DateTime dueDate;
  final AdminDashboardTodoClientPreview? client;
}
