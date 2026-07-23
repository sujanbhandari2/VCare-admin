import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';
import 'package:vcare_admin/shared/models/loadable_list_item.dart';

class SalesHistoryPayerAddress {
  const SalesHistoryPayerAddress({
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.zip,
  });

  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? zip;
}

class SalesHistoryPayer {
  const SalesHistoryPayer({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.profileId,
    this.profilePreviewLink,
  });

  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final SalesHistoryPayerAddress? address;
  final String? profileId;
  final String? profilePreviewLink;
}

class SalesHistoryPaymentMethod {
  const SalesHistoryPaymentMethod({
    required this.id,
    this.type,
    this.cardBrand,
    this.cardLast4,
    this.cardExpMonth,
    this.cardExpYear,
    this.nickname,
  });

  final String id;
  final String? type;
  final String? cardBrand;
  final String? cardLast4;
  final int? cardExpMonth;
  final int? cardExpYear;
  final String? nickname;
}

class SalesHistoryItem implements LoadableListItem {
  const SalesHistoryItem({
    required this.id,
    this.tenantId,
    this.payerId,
    this.payer,
    this.subscriptionId,
    this.paymentMethodId,
    this.paymentMethod,
    this.type,
    required this.status,
    required this.amount,
    this.currency,
    this.commissionAmount,
    this.billingStartDate,
    this.billingEndDate,
    required this.transactionDate,
    this.invoiceNumber,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? tenantId;
  final String? payerId;
  final SalesHistoryPayer? payer;
  final String? subscriptionId;
  final String? paymentMethodId;
  final SalesHistoryPaymentMethod? paymentMethod;
  final String? type;
  final SalesTransactionStatus status;
  final double amount;
  final String? currency;
  final double? commissionAmount;
  final String? billingStartDate;
  final String? billingEndDate;
  final String transactionDate;
  final String? invoiceNumber;
  final String? createdAt;
  final String? updatedAt;

  String get displayPayerName {
    final name = payer?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = (payerId ?? payer?.id ?? '').trim();
    if (id.isEmpty) return 'Payer';
    if (id.length <= 8) return 'Payer $id';
    return 'Payer ${id.substring(0, 8)}…';
  }
}
