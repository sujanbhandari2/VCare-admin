import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_transaction_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';

extension ClientTransactionModelMapper on ClientTransactionModel {
  ClientTransaction toEntity() {
    final txDate = transactionDate ?? createdAt ?? '';
    final billingPeriod = [
      billingStartDate,
      billingEndDate,
    ].where((part) => part != null && part.isNotEmpty).join(' - ');

    return ClientTransaction(
      id: id,
      membershipTitle: humanizeApiEnum(type),
      date: formatClientDate(txDate),
      dateTime: txDate,
      payDate: billingPeriod.isEmpty ? formatClientDate(txDate) : billingPeriod,
      amount: parseAmount(amount),
      status: _mapStatus(status),
      reference: invoiceNumber ?? id,
      paymentMethodLabel: paymentMethodId,
      description: type,
      note: null,
      dependentName: payerName,
      dependentRelation: null,
    );
  }

  ClientTransactionStatus _mapStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'SUCCEEDED':
      case 'SUCCESS':
      case 'PAID':
        return ClientTransactionStatus.succeeded;
      case 'FAILED':
        return ClientTransactionStatus.failed;
      case 'PENDING':
        return ClientTransactionStatus.pending;
      default:
        return ClientTransactionStatus.onHold;
    }
  }
}
