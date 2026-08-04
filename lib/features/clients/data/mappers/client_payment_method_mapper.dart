import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_payment_method_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

extension ClientPaymentMethodModelMapper on ClientPaymentMethodModel {
  ClientPaymentMethod toEntity() {
    return ClientPaymentMethod(
      id: id,
      type: _mapType(type),
      label: _buildLabel(),
      last4: cardLast4?.trim().isNotEmpty == true ? cardLast4!.trim() : null,
      expMonth: cardExpMonth,
      expYear: cardExpYear,
      isPrimary: isPrimary,
    );
  }

  String _buildLabel() {
    final trimmedNickname = nickname?.trim();
    if (trimmedNickname != null && trimmedNickname.isNotEmpty) {
      return trimmedNickname;
    }

    final apiType = type?.toUpperCase();
    if (apiType == 'CARD' ||
        apiType == 'CREDIT_CARD' ||
        apiType == 'DEBIT_CARD') {
      final brand = cardBrand?.trim().isNotEmpty == true
          ? cardBrand!.trim()
          : 'Card';
      final last4 = cardLast4?.trim();
      if (last4 != null && last4.isNotEmpty) {
        return '$brand •• $last4';
      }
      return brand;
    }

    if (apiType == 'BANK' || apiType == 'BANK_TRANSFER') {
      return 'Bank account';
    }
    if (apiType == 'ACH') return 'ACH account';
    if (apiType == 'CASH') return 'Cash';

    return humanizeApiEnum(type);
  }

  ClientPaymentMethodType _mapType(String? value) {
    switch (value?.toUpperCase()) {
      case 'CARD':
      case 'CREDIT_CARD':
      case 'DEBIT_CARD':
        return ClientPaymentMethodType.creditDebitCard;
      case 'BANK':
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

extension ClientPaymentMethodModelListMapper
    on Iterable<ClientPaymentMethodModel> {
  List<ClientPaymentMethod> toActiveEntities() {
    return where((model) => model.isActive)
        .map((model) => model.toEntity())
        .toList();
  }
}

/// Detects card brand from number digits — parity with web `detectCardBrand`.
String detectCardBrand(String cardNumber) {
  final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^4').hasMatch(digits)) return 'Visa';
  if (RegExp(r'^5[1-5]').hasMatch(digits) ||
      RegExp(r'^2[2-7]').hasMatch(digits)) {
    return 'Mastercard';
  }
  if (RegExp(r'^3[47]').hasMatch(digits)) return 'Amex';
  if (RegExp(r'^6(?:011|5)').hasMatch(digits)) return 'Discover';
  return 'Card';
}
