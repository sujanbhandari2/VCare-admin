/// Input for adding a client payment method.
/// API types match web: CARD | BANK | ACH | CASH.
class AddClientPaymentMethodRequest {
  const AddClientPaymentMethodRequest._({
    required this.type,
    this.paymentToken,
    this.cardLast4,
    this.cardBrand,
    this.cardExpMonth,
    this.cardExpYear,
    this.nickname,
  });

  factory AddClientPaymentMethodRequest.card({
    required String paymentToken,
    required String cardLast4,
    required String cardBrand,
    required int cardExpMonth,
    required int cardExpYear,
    String? nickname,
  }) {
    return AddClientPaymentMethodRequest._(
      type: 'CARD',
      paymentToken: paymentToken,
      cardLast4: cardLast4,
      cardBrand: cardBrand,
      cardExpMonth: cardExpMonth,
      cardExpYear: cardExpYear,
      nickname: nickname,
    );
  }

  factory AddClientPaymentMethodRequest.bank({
    String? paymentToken,
    String? nickname,
  }) {
    return AddClientPaymentMethodRequest._(
      type: 'BANK',
      paymentToken: paymentToken,
      nickname: nickname,
    );
  }

  factory AddClientPaymentMethodRequest.ach({
    String? paymentToken,
    String? nickname,
  }) {
    return AddClientPaymentMethodRequest._(
      type: 'ACH',
      paymentToken: paymentToken,
      nickname: nickname,
    );
  }

  factory AddClientPaymentMethodRequest.cash({String? nickname}) {
    return AddClientPaymentMethodRequest._(type: 'CASH', nickname: nickname);
  }

  final String type;
  final String? paymentToken;
  final String? cardLast4;
  final String? cardBrand;
  final int? cardExpMonth;
  final int? cardExpYear;
  final String? nickname;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (paymentToken != null && paymentToken!.isNotEmpty)
        'paymentToken': paymentToken,
      if (cardLast4 != null) 'cardLast4': cardLast4,
      if (cardBrand != null) 'cardBrand': cardBrand,
      if (cardExpMonth != null) 'cardExpMonth': cardExpMonth,
      if (cardExpYear != null) 'cardExpYear': cardExpYear,
      if (nickname != null && nickname!.isNotEmpty) 'nickname': nickname,
    };
  }
}
