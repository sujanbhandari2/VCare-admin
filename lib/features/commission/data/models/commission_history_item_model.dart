class CommissionHistoryItemModel {
  const CommissionHistoryItemModel({
    required this.id,
    this.tenantId,
    this.commissionSettingsId,
    this.transactionId,
    this.agencyGroupId,
    this.referrerAgentId,
    required this.clientId,
    this.clientName,
    this.clientProfilePreviewLink,
    this.offeringName,
    this.type,
    this.commissionValue,
    required this.commissionType,
    this.commissionAmount,
    this.salesAmount,
    required this.status,
    this.paidAt,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? tenantId;
  final String? commissionSettingsId;
  final String? transactionId;
  final String? agencyGroupId;
  final String? referrerAgentId;
  final String clientId;
  final String? clientName;
  final String? clientProfilePreviewLink;
  final String? offeringName;
  final String? type;
  final String? commissionValue;
  final String commissionType;
  final double? commissionAmount;
  final double? salesAmount;
  final String status;
  final String? paidAt;
  final String? notes;
  final String createdAt;
  final String? updatedAt;

  factory CommissionHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final clientRaw = json['client'];
    final nestedName = clientRaw is Map
        ? clientRaw['name']?.toString() ??
              [clientRaw['firstName'], clientRaw['lastName']]
                  .whereType<String>()
                  .where((part) => part.trim().isNotEmpty)
                  .join(' ')
        : null;

    final clientNameRaw = json['clientName'];
    final clientName = clientNameRaw is String
        ? clientNameRaw
        : (nestedName?.trim().isNotEmpty == true ? nestedName : null);

    final photoRaw =
        json['clientProfilePreviewLink'] ??
        (clientRaw is Map ? clientRaw['profilePreviewLink'] : null);

    return CommissionHistoryItemModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      commissionSettingsId: json['commissionSettingsId']?.toString(),
      transactionId: json['transactionId']?.toString(),
      agencyGroupId: json['agencyGroupId']?.toString(),
      referrerAgentId: json['referrerAgentId']?.toString(),
      clientId: json['clientId']?.toString() ?? '',
      clientName: clientName?.trim().isNotEmpty == true ? clientName : null,
      clientProfilePreviewLink: photoRaw?.toString().trim().isNotEmpty == true
          ? photoRaw.toString().trim()
          : null,
      offeringName: json['offeringName']?.toString().trim().isNotEmpty == true
          ? json['offeringName'].toString().trim()
          : null,
      type: json['type']?.toString(),
      commissionValue: json['commissionValue']?.toString(),
      commissionType: json['commissionType']?.toString() ?? '',
      commissionAmount: _asDouble(json['commissionAmount']),
      salesAmount: _asDouble(json['salesAmount']),
      status: json['status']?.toString() ?? '',
      paidAt: json['paidAt']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
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
