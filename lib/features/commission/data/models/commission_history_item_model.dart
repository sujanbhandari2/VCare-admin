class CommissionHistoryItemModel {
  const CommissionHistoryItemModel({
    required this.id,
    required this.clientId,
    this.clientName,
    required this.commissionValue,
    required this.commissionType,
    required this.commissionAmount,
    required this.status,
    this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String? clientName;
  final String commissionValue;
  final String commissionType;
  final String commissionAmount;
  final String status;
  final String? paidAt;
  final String createdAt;

  factory CommissionHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final clientRaw = json['client'];
    final nestedName = clientRaw is Map
        ? clientRaw['name']?.toString() ??
            [
              clientRaw['firstName'],
              clientRaw['lastName'],
            ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ')
        : null;

    return CommissionHistoryItemModel(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ??
          json['client']?.toString() ??
          (nestedName?.trim().isNotEmpty == true ? nestedName : null),
      commissionValue: json['commissionValue']?.toString() ?? '',
      commissionType: json['commissionType']?.toString() ?? '',
      commissionAmount: json['commissionAmount']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paidAt: json['paidAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
