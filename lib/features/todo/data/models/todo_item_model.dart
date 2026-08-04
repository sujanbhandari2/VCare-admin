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
    this.failureReason,
  });

  final String transactionId;
  final String payerId;
  final String payerName;
  final String amount;
  final String currency;
  final String? invoiceNumber;
  final String? failureReason;

  /// Parity with web `todoDetailsSchema` + `mapPaymentFailedTodo`.
  ///
  /// Prefer canonical API fields (`name`, `relatedId`, `code`, `reason`) and
  /// fall back to older Flutter-shaped keys when present.
  factory TodoPaymentFailedDetailsModel.fromJson(
    Map<String, dynamic> json, {
    String? resourceTransactionId,
  }) {
    final reason = _firstNonEmptyString(json, const ['reason', 'failureReason']);
    final invoice = _firstNonEmptyString(json, const ['code', 'invoiceNumber']);
    final transactionId =
        (resourceTransactionId?.trim().isNotEmpty == true
            ? resourceTransactionId!.trim()
            : null) ??
        _firstNonEmptyString(json, const ['transactionId']) ??
        '';

    return TodoPaymentFailedDetailsModel(
      transactionId: transactionId,
      payerId:
          _firstNonEmptyString(json, const ['relatedId', 'payerId']) ?? '',
      payerName: _firstNonEmptyString(json, const ['name', 'payerName']) ?? '',
      amount: json['amount']?.toString() ?? '',
      currency: _firstNonEmptyString(json, const ['currency']) ?? '',
      invoiceNumber: invoice,
      failureReason: reason,
    );
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
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

  /// Returns null when required payment-failed fields are missing (web drops item).
  TodoPaymentFailedDetailsModel? paymentFailedDetails() {
    final raw = details;
    if (raw == null) return null;

    final model = TodoPaymentFailedDetailsModel.fromJson(
      raw,
      resourceTransactionId: resource?.id,
    );

    if (model.payerName.isEmpty ||
        model.payerId.isEmpty ||
        model.currency.isEmpty ||
        model.transactionId.isEmpty) {
      return null;
    }

    final amount = double.tryParse(model.amount);
    if (amount == null || !amount.isFinite) return null;

    return model;
  }

  TodoW9FormDetailsModel w9FormDetails({required String? agentId}) {
    final raw = details;
    final code = raw?['code']?.toString().trim();
    return TodoW9FormDetailsModel(
      documentType: (code != null && code.isNotEmpty) ? code : 'W-9 Form',
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
