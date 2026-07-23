import 'package:vcare_admin/features/todo/data/models/todo_item_model.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';

extension TodoItemModelMapper on TodoItemModel {
  TodoItem toEntity() {
    final todoType = TodoType.fromApi(type);
    final resourceEntity = resource == null
        ? null
        : TodoResource(type: resource!.type, id: resource!.id);
    final paymentDetails = todoType == TodoType.paymentFailed
        ? paymentFailedDetails()?.toEntity()
        : null;
    final w9Details = todoType == TodoType.w9FormMissing
        ? w9FormDetails(
            agentId: resourceEntity?.id.trim().isNotEmpty == true
                ? resourceEntity!.id.trim()
                : null,
          ).toEntity()
        : null;

    return TodoItem(
      id: id,
      type: todoType,
      title: title.trim().isNotEmpty ? title.trim() : 'Task',
      description: todoType == TodoType.w9FormMissing
          ? _cleanW9Description(description)
          : description.trim(),
      occurredAt: DateTime.tryParse(occurredAt) ?? DateTime.now(),
      resource: resourceEntity,
      paymentFailedDetails: paymentDetails,
      w9FormDetails: w9Details,
      rawType: type,
    );
  }
}

extension TodoPaymentFailedDetailsModelMapper on TodoPaymentFailedDetailsModel {
  TodoPaymentFailedDetails toEntity() {
    return TodoPaymentFailedDetails(
      transactionId: transactionId,
      payerId: payerId,
      payerName: payerName.trim().isNotEmpty ? payerName.trim() : 'Client',
      amount: double.tryParse(amount) ?? 0,
      currency: currency.trim().isNotEmpty
          ? currency.trim().toUpperCase()
          : 'USD',
      invoiceNumber: invoiceNumber?.trim().isNotEmpty == true
          ? invoiceNumber!.trim()
          : null,
    );
  }
}

extension TodoW9FormDetailsModelMapper on TodoW9FormDetailsModel {
  TodoW9FormDetails toEntity() {
    return TodoW9FormDetails(
      documentType: documentType.trim().isNotEmpty
          ? documentType.trim()
          : 'W-9 Form',
      agentId: agentId?.trim().isNotEmpty == true ? agentId!.trim() : null,
    );
  }
}

/// Matches web `mapW9FormMissingTodo` description cleanup.
String _cleanW9Description(String raw) {
  var cleaned = raw
      .replaceAll(RegExp(r'\bagent\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  if (cleaned.isEmpty) return cleaned;
  cleaned = cleaned.replaceFirst(RegExp(r'[.!?]?$'), '.');
  return cleaned;
}
