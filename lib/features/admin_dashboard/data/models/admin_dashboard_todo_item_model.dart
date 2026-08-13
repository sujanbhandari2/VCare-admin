class AdminDashboardTodoResourceModel {
  const AdminDashboardTodoResourceModel({
    required this.type,
    required this.id,
  });

  factory AdminDashboardTodoResourceModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardTodoResourceModel(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
    );
  }

  final String type;
  final String id;
}

class AdminDashboardPaymentDetailsModel {
  const AdminDashboardPaymentDetailsModel({
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

  factory AdminDashboardPaymentDetailsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminDashboardPaymentDetailsModel(
      name: json['name']?.toString(),
      amount: json['amount']?.toString(),
      currency: json['currency']?.toString(),
      code: json['code']?.toString(),
      relatedId: json['relatedId']?.toString(),
      membershipName: json['membershipName']?.toString(),
      billingStartDate: json['billingStartDate']?.toString(),
      billingEndDate: json['billingEndDate']?.toString(),
      failureReason: json['failureReason']?.toString(),
      failureMessage: json['failureMessage']?.toString(),
      failureActionMessage: json['failureActionMessage']?.toString(),
    );
  }

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

class AdminDashboardTodoClientPreviewModel {
  const AdminDashboardTodoClientPreviewModel({
    required this.id,
    required this.name,
  });

  factory AdminDashboardTodoClientPreviewModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminDashboardTodoClientPreviewModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
}

class AdminDashboardTodoItemModel {
  const AdminDashboardTodoItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.resource,
    this.details,
    this.priority,
    this.status,
    this.dueDate,
    this.client,
  });

  factory AdminDashboardTodoItemModel.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final resourceJson = json['resource'];
    final resource = resourceJson is Map
        ? AdminDashboardTodoResourceModel.fromJson(
            Map<String, dynamic>.from(resourceJson),
          )
        : const AdminDashboardTodoResourceModel(type: '', id: '');

    AdminDashboardPaymentDetailsModel? details;
    if (json['details'] is Map) {
      details = AdminDashboardPaymentDetailsModel.fromJson(
        Map<String, dynamic>.from(json['details'] as Map),
      );
    }

    AdminDashboardTodoClientPreviewModel? client;
    if (json['client'] is Map) {
      client = AdminDashboardTodoClientPreviewModel.fromJson(
        Map<String, dynamic>.from(json['client'] as Map),
      );
    }

    return AdminDashboardTodoItemModel(
      id: json['id']?.toString() ?? '',
      type: type,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      occurredAt: json['occurredAt']?.toString() ?? '',
      resource: resource,
      details: details,
      priority: json['priority']?.toString(),
      status: json['status']?.toString(),
      dueDate: json['dueDate']?.toString(),
      client: client,
    );
  }

  final String id;
  final String type;
  final String title;
  final String description;
  final String occurredAt;
  final AdminDashboardTodoResourceModel resource;
  final AdminDashboardPaymentDetailsModel? details;
  final String? priority;
  final String? status;
  final String? dueDate;
  final AdminDashboardTodoClientPreviewModel? client;

  bool get isPaymentFailed => type == 'PAYMENT_FAILED';
  bool get isTaskOverdue => type == 'TASK_OVERDUE';
  bool get isTaskDueSoon => type == 'TASK_DUE_SOON';
}
