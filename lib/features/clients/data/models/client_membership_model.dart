import 'client_list_item_model.dart';

class ClientOfferingDetailsModel {
  const ClientOfferingDetailsModel({
    this.offeringId,
    this.offeringName,
    this.description,
    this.offeringType,
    this.billingModel,
    this.billingInterval,
    this.fee,
    this.registrationFee,
  });

  final String? offeringId;
  final String? offeringName;
  final String? description;
  final String? offeringType;
  final String? billingModel;
  final String? billingInterval;
  final String? fee;
  final String? registrationFee;

  factory ClientOfferingDetailsModel.fromJson(Map<String, dynamic> json) {
    return ClientOfferingDetailsModel(
      offeringId: json['offeringId']?.toString(),
      offeringName: json['offeringName']?.toString(),
      description: json['description']?.toString(),
      offeringType: json['offeringType']?.toString(),
      billingModel: json['billingModel']?.toString(),
      billingInterval: json['billingInterval']?.toString(),
      fee: json['fee']?.toString(),
      registrationFee: json['registrationFee']?.toString(),
    );
  }
}

class ClientMembershipModel {
  const ClientMembershipModel({
    required this.id,
    this.clientId,
    this.enrollmentType,
    this.enrollmentDisplayLabel,
    this.status,
    this.startDate,
    this.endDate,
    this.note,
    this.offeringDetails,
    this.client,
    this.relationshipToPrimary,
  });

  final String id;
  final String? clientId;
  final String? enrollmentType;
  final String? enrollmentDisplayLabel;
  final String? status;
  final String? startDate;
  final String? endDate;
  final String? note;
  final ClientOfferingDetailsModel? offeringDetails;
  final ClientListItemModel? client;
  final String? relationshipToPrimary;

  factory ClientMembershipModel.fromJson(Map<String, dynamic> json) {
    return ClientMembershipModel(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString(),
      enrollmentType: json['enrollmentType']?.toString(),
      enrollmentDisplayLabel: json['enrollmentDisplayLabel']?.toString(),
      status: json['status']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      note: json['note']?.toString(),
      offeringDetails: json['offeringDetails'] is Map<String, dynamic>
          ? ClientOfferingDetailsModel.fromJson(
              json['offeringDetails'] as Map<String, dynamic>,
            )
          : null,
      client: json['client'] is Map<String, dynamic>
          ? ClientListItemModel.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      relationshipToPrimary: json['relationshipToPrimary']?.toString(),
    );
  }
}

class ClientMembershipsResultModel {
  const ClientMembershipsResultModel({
    required this.clientId,
    required this.details,
    required this.totalGroup,
  });

  final String clientId;
  final List<ClientMembershipModel> details;
  final int totalGroup;

  factory ClientMembershipsResultModel.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    return ClientMembershipsResultModel(
      clientId: json['clientId']?.toString() ?? '',
      details: details is List
          ? details
                .whereType<Map>()
                .map(
                  (item) => ClientMembershipModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      totalGroup: _asInt(json['totalGroup']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
