import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/shared/models/loadable_list_item.dart';

class TodoResource {
  const TodoResource({required this.type, required this.id});

  final String type;
  final String id;
}

class TodoPaymentFailedDetails {
  const TodoPaymentFailedDetails({
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
  final double amount;
  final String currency;
  final String? invoiceNumber;

  /// Raw failure text from API `details.reason` / `details.failureReason`.
  final String? failureReason;
}

class TodoW9FormDetails {
  const TodoW9FormDetails({
    required this.documentType,
    this.agentId,
  });

  /// Document type **label** sent on upload (e.g. `"W-9 Form"`), not the key.
  final String documentType;
  final String? agentId;
}

class TodoItem implements LoadableListItem {
  const TodoItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.occurredAt,
    this.resource,
    this.paymentFailedDetails,
    this.w9FormDetails,
    this.rawType,
  });

  final String id;
  final TodoType type;
  final String title;
  final String description;
  final DateTime occurredAt;
  final TodoResource? resource;
  final TodoPaymentFailedDetails? paymentFailedDetails;
  final TodoW9FormDetails? w9FormDetails;

  /// Original API type string for unknown/future sources.
  final String? rawType;

  bool get isPaymentFailed => type == TodoType.paymentFailed;

  bool get isW9FormMissing => type == TodoType.w9FormMissing;

  bool get isCompleteProfile => type == TodoType.completeProfile;

  String? get transactionId =>
      paymentFailedDetails?.transactionId ??
      (resource?.type.toUpperCase() == 'TRANSACTION' ? resource?.id : null);

  String? get agentId =>
      w9FormDetails?.agentId ??
      (resource?.id.trim().isNotEmpty == true ? resource!.id.trim() : null);

  String get displayPayerName {
    final name = paymentFailedDetails?.payerName.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Client';
  }

  String get w9DocumentTypeLabel {
    final fromDetails = w9FormDetails?.documentType.trim();
    if (fromDetails != null && fromDetails.isNotEmpty) return fromDetails;
    return 'W-9 Form';
  }
}
