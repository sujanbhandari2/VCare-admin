import 'package:vcare_admin/features/commission/data/models/sales_history_item_model.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';

extension SalesHistoryItemModelMapper on SalesHistoryItemModel {
  SalesHistoryItem toEntity() {
    return SalesHistoryItem(
      id: id,
      tenantId: tenantId,
      payerId: payerId,
      payer: payer?.toEntity(),
      subscriptionId: subscriptionId,
      paymentMethodId: paymentMethodId,
      paymentMethod: paymentMethod?.toEntity(),
      type: type,
      status: _mapStatus(status),
      amount: amount,
      currency: currency,
      commissionAmount: commissionAmount,
      billingStartDate: billingStartDate,
      billingEndDate: billingEndDate,
      transactionDate: transactionDate,
      invoiceNumber: invoiceNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  SalesTransactionStatus _mapStatus(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return SalesTransactionStatus.pending;
      case 'PAID':
        return SalesTransactionStatus.paid;
      case 'FAILED':
        return SalesTransactionStatus.failed;
      case 'REFUNDED':
        return SalesTransactionStatus.refunded;
      case 'VOIDED':
        return SalesTransactionStatus.voided;
      default:
        return SalesTransactionStatus.unknown;
    }
  }
}

extension SalesHistoryPayerModelMapper on SalesHistoryPayerModel {
  SalesHistoryPayer toEntity() {
    return SalesHistoryPayer(
      id: id,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      address: address?.toEntity(),
      profileId: profileId,
      profilePreviewLink: profilePreviewLink,
    );
  }
}

extension SalesHistoryPayerAddressModelMapper on SalesHistoryPayerAddressModel {
  SalesHistoryPayerAddress toEntity() {
    return SalesHistoryPayerAddress(
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      zip: zip,
    );
  }
}

extension SalesHistoryPaymentMethodModelMapper
    on SalesHistoryPaymentMethodModel {
  SalesHistoryPaymentMethod toEntity() {
    return SalesHistoryPaymentMethod(
      id: id,
      type: type,
      cardBrand: cardBrand,
      cardLast4: cardLast4,
      cardExpMonth: cardExpMonth,
      cardExpYear: cardExpYear,
      nickname: nickname,
    );
  }
}
