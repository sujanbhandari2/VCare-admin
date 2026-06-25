class ClientTransactionModel {
  const ClientTransactionModel({
    required this.id,
    this.tenantId,
    this.payerId,
    this.subscriptionId,
    this.paymentMethodId,
    this.type,
    this.status,
    this.amount,
    this.currency,
    this.commissionAmount,
    this.billingStartDate,
    this.billingEndDate,
    this.transactionDate,
    this.invoiceNumber,
    this.createdAt,
    this.updatedAt,
    this.payerName,
    this.payerEmail,
    this.payerPhoneNumber,
  });

  final String id;
  final String? tenantId;
  final String? payerId;
  final String? subscriptionId;
  final String? paymentMethodId;
  final String? type;
  final String? status;
  final String? amount;
  final String? currency;
  final String? commissionAmount;
  final String? billingStartDate;
  final String? billingEndDate;
  final String? transactionDate;
  final String? invoiceNumber;
  final String? createdAt;
  final String? updatedAt;
  final String? payerName;
  final String? payerEmail;
  final String? payerPhoneNumber;

  factory ClientTransactionModel.fromJson(Map<String, dynamic> json) {
    final payer = json['payer'];
    Map<String, dynamic>? payerMap;
    if (payer is Map<String, dynamic>) {
      payerMap = payer;
    } else if (payer is Map) {
      payerMap = Map<String, dynamic>.from(payer);
    }

    return ClientTransactionModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      payerId: json['payerId']?.toString(),
      subscriptionId: json['subscriptionId']?.toString(),
      paymentMethodId: json['paymentMethodId']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      amount: json['amount']?.toString(),
      currency: json['currency']?.toString(),
      commissionAmount: json['commissionAmount']?.toString(),
      billingStartDate: json['billingStartDate']?.toString(),
      billingEndDate: json['billingEndDate']?.toString(),
      transactionDate: json['transactionDate']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      payerName: payerMap?['name']?.toString(),
      payerEmail: payerMap?['email']?.toString(),
      payerPhoneNumber: payerMap?['phoneNumber']?.toString(),
    );
  }
}
