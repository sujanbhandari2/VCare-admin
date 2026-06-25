import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_payment_method_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

extension ClientPaymentMethodModelMapper on ClientPaymentMethodModel {
  ClientPaymentMethod toEntity() {
    final typeLabel = humanizeApiEnum(type);
    final cardLabel = cardLast4 != null && cardLast4!.isNotEmpty
        ? '${cardBrand ?? 'Card'} •••• $cardLast4'
        : null;

    return ClientPaymentMethod(
      id: id,
      type: _mapType(type),
      label: nickname?.trim().isNotEmpty == true
          ? nickname!.trim()
          : cardLabel ?? typeLabel,
      last4: cardLast4,
      isPrimary: isPrimary,
    );
  }

  ClientPaymentMethodType _mapType(String? value) {
    switch (value?.toUpperCase()) {
      case 'CARD':
      case 'CREDIT_CARD':
      case 'DEBIT_CARD':
        return ClientPaymentMethodType.creditDebitCard;
      case 'BANK_TRANSFER':
      case 'ACH':
        return ClientPaymentMethodType.bankTransfer;
      case 'CASH':
        return ClientPaymentMethodType.cash;
      case 'CHECK':
        return ClientPaymentMethodType.check;
      default:
        return ClientPaymentMethodType.others;
    }
  }
}
