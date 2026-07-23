class TodoResourceModel {
  const TodoResourceModel({required this.type, required this.id});

  final String type;
  final String id;

  factory TodoResourceModel.fromJson(Map<String, dynamic> json) {
    return TodoResourceModel(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
    );
  }
}

class TodoPaymentFailedDetailsModel {
  const TodoPaymentFailedDetailsModel({
    required this.transactionId,
    required this.payerId,
    required this.payerName,
    required this.amount,
    required this.currency,
    this.invoiceNumber,
  });

  final String transactionId;
  final String payerId;
  final String payerName;
  final String amount;
  final String currency;
  final String? invoiceNumber;

  factory TodoPaymentFailedDetailsModel.fromJson(Map<String, dynamic> json) {
    return TodoPaymentFailedDetailsModel(
      transactionId: json['transactionId']?.toString() ?? '',
      payerId: json['payerId']?.toString() ?? '',
      payerName: json['payerName']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'USD',
      invoiceNumber: json['invoiceNumber']?.toString(),
    );
  }
}

class TodoItemModel {
  const TodoItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.occurredAt,
    this.resource,
    this.details,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String occurredAt;
  final TodoResourceModel? resource;
  final Map<String, dynamic>? details;

  factory TodoItemModel.fromJson(Map<String, dynamic> json) {
    final resourceRaw = json['resource'];
    TodoResourceModel? resource;
    if (resourceRaw is Map) {
      resource = TodoResourceModel.fromJson(
        Map<String, dynamic>.from(resourceRaw),
      );
    }

    final detailsRaw = json['details'];
    Map<String, dynamic>? details;
    if (detailsRaw is Map) {
      details = Map<String, dynamic>.from(detailsRaw);
    }

    return TodoItemModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      occurredAt: json['occurredAt']?.toString() ?? '',
      resource: resource,
      details: details,
    );
  }

  TodoPaymentFailedDetailsModel? paymentFailedDetails() {
    final raw = details;
    if (raw == null) return null;
    return TodoPaymentFailedDetailsModel.fromJson(raw);
  }

  TodoW9FormDetailsModel w9FormDetails({required String? agentId}) {
    final raw = details;
    final code = raw?['code']?.toString().trim();
    return TodoW9FormDetailsModel(
      documentType: (code != null && code.isNotEmpty)
          ? code
          : 'W-9 Form',
      agentId: agentId,
    );
  }
}

class TodoW9FormDetailsModel {
  const TodoW9FormDetailsModel({
    required this.documentType,
    this.agentId,
  });

  final String documentType;
  final String? agentId;
}
