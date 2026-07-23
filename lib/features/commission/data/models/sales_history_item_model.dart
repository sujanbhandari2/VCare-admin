class SalesHistoryPayerAddressModel {
  const SalesHistoryPayerAddressModel({
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

  factory SalesHistoryPayerAddressModel.fromJson(Map<String, dynamic> json) {
    return SalesHistoryPayerAddressModel(
      line1: json['line1']?.toString() ?? json['addressLine1']?.toString(),
      line2: json['line2']?.toString() ?? json['addressLine2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zip: json['zip']?.toString() ?? json['postalCode']?.toString(),
    );
  }
}

class SalesHistoryPayerModel {
  const SalesHistoryPayerModel({
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
  final SalesHistoryPayerAddressModel? address;
  final String? profileId;
  final String? profilePreviewLink;

  factory SalesHistoryPayerModel.fromJson(Map<String, dynamic> json) {
    final addressRaw = json['address'];
    SalesHistoryPayerAddressModel? address;
    if (addressRaw is Map) {
      address = SalesHistoryPayerAddressModel.fromJson(
        Map<String, dynamic>.from(addressRaw),
      );
    }

    return SalesHistoryPayerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      address: address,
      profileId: json['profileId']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
    );
  }
}

class SalesHistoryPaymentMethodModel {
  const SalesHistoryPaymentMethodModel({
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

  factory SalesHistoryPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return SalesHistoryPaymentMethodModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      cardLast4: json['cardLast4']?.toString(),
      cardExpMonth: _asInt(json['cardExpMonth']),
      cardExpYear: _asInt(json['cardExpYear']),
      nickname: json['nickname']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class SalesHistoryItemModel {
  const SalesHistoryItemModel({
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
  final SalesHistoryPayerModel? payer;
  final String? subscriptionId;
  final String? paymentMethodId;
  final SalesHistoryPaymentMethodModel? paymentMethod;
  final String? type;
  final String status;
  final double amount;
  final String? currency;
  final double? commissionAmount;
  final String? billingStartDate;
  final String? billingEndDate;
  final String transactionDate;
  final String? invoiceNumber;
  final String? createdAt;
  final String? updatedAt;

  factory SalesHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final payerRaw = json['payer'];
    SalesHistoryPayerModel? payer;
    if (payerRaw is Map) {
      payer = SalesHistoryPayerModel.fromJson(
        Map<String, dynamic>.from(payerRaw),
      );
    }

    final paymentMethodRaw = json['paymentMethod'];
    SalesHistoryPaymentMethodModel? paymentMethod;
    if (paymentMethodRaw is Map) {
      paymentMethod = SalesHistoryPaymentMethodModel.fromJson(
        Map<String, dynamic>.from(paymentMethodRaw),
      );
    }

    return SalesHistoryItemModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      payerId: json['payerId']?.toString(),
      payer: payer,
      subscriptionId: json['subscriptionId']?.toString(),
      paymentMethodId: json['paymentMethodId']?.toString(),
      paymentMethod: paymentMethod,
      type: json['type']?.toString(),
      status: json['status']?.toString() ?? '',
      amount: _asDouble(json['amount']) ?? 0,
      currency: json['currency']?.toString(),
      commissionAmount: _asDouble(json['commissionAmount']),
      billingStartDate: json['billingStartDate']?.toString(),
      billingEndDate: json['billingEndDate']?.toString(),
      transactionDate:
          json['transactionDate']?.toString() ??
          json['createdAt']?.toString() ??
          '',
      invoiceNumber: json['invoiceNumber']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
