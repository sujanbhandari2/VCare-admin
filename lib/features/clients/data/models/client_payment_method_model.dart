class ClientPaymentMethodModel {
  const ClientPaymentMethodModel({
    required this.id,
    this.tenantId,
    this.clientId,
    this.type,
    this.isPrimary = false,
    this.isActive = true,
    this.cardLast4,
    this.cardBrand,
    this.cardExpMonth,
    this.cardExpYear,
    this.nickname,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? tenantId;
  final String? clientId;
  final String? type;
  final bool isPrimary;
  final bool isActive;
  final String? cardLast4;
  final String? cardBrand;
  final int? cardExpMonth;
  final int? cardExpYear;
  final String? nickname;
  final String? createdAt;
  final String? updatedAt;

  factory ClientPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return ClientPaymentMethodModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      clientId: json['clientId']?.toString(),
      type: json['type']?.toString(),
      isPrimary: json['isPrimary'] == true,
      isActive: json['isActive'] == true,
      cardLast4: json['cardLast4']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      cardExpMonth: _asInt(json['cardExpMonth']),
      cardExpYear: _asInt(json['cardExpYear']),
      nickname: json['nickname']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
