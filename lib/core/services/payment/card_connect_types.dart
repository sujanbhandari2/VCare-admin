class CardConnectCardTokenResult {
  const CardConnectCardTokenResult({
    required this.paymentToken,
    required this.cardLast4,
    required this.cardBrand,
    required this.cardExpMonth,
    required this.cardExpYear,
  });

  final String paymentToken;
  final String cardLast4;
  final String cardBrand;
  final int cardExpMonth;
  final int cardExpYear;
}

class CardConnectBankTokenResult {
  const CardConnectBankTokenResult({
    required this.paymentToken,
    this.accountLast4,
  });

  final String paymentToken;
  final String? accountLast4;
}

class CardSecureTokenizeResponse {
  const CardSecureTokenizeResponse({
    required this.errorCode,
    required this.message,
    this.token,
  });

  factory CardSecureTokenizeResponse.fromJson(Map<String, dynamic> json) {
    final rawCode = json['errorcode'] ?? json['errorCode'];
    final code = rawCode is int
        ? rawCode
        : int.tryParse(rawCode?.toString() ?? '') ?? -1;
    return CardSecureTokenizeResponse(
      errorCode: code,
      message: (json['message'] ?? json['errorMessage'] ?? '').toString(),
      token: json['token']?.toString(),
    );
  }

  final int errorCode;
  final String message;
  final String? token;

  bool get isSuccess => errorCode == 0 && token != null && token!.isNotEmpty;
}

class CardConnectTokenizeException implements Exception {
  CardConnectTokenizeException(this.message);

  final String message;

  @override
  String toString() => message;
}
