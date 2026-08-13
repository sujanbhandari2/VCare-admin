import 'package:vcare_admin/features/admin_dashboard/domain/entities/admin_dashboard_todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';

extension AdminDashboardFailedPaymentTodoMapper
    on AdminDashboardFailedPaymentTodoItem {
  /// Maps admin dashboard payment todo into the shared recovery sheet model.
  TodoItem toTodoItem() {
    final amount = double.tryParse(details.amount ?? '') ?? 0;
    final currency = details.currency?.trim().isNotEmpty == true
        ? details.currency!.trim().toUpperCase()
        : 'USD';
    final payerName = details.name?.trim().isNotEmpty == true
        ? details.name!.trim()
        : 'Client';
    final payerId = details.relatedId?.trim() ?? '';

    return TodoItem(
      id: id,
      type: TodoType.paymentFailed,
      title: title,
      description: description,
      occurredAt: occurredAt,
      resource: TodoResource(type: resource.type, id: resource.id),
      paymentFailedDetails: TodoPaymentFailedDetails(
        transactionId: resource.id,
        payerId: payerId,
        payerName: payerName,
        amount: amount,
        currency: currency,
        invoiceNumber: details.code,
        failureReason: details.failureReason ?? details.failureMessage,
      ),
    );
  }
}
