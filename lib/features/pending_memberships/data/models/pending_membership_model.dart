/// Raw `client` block on an enrollment record.
class MembershipClientModel {
  const MembershipClientModel({
    required this.id,
    this.clientType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.companyName,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.profilePreviewLink,
    this.ssnLast4,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
  });

  final String id;
  final String? clientType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? companyName;
  final String? email;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? profilePreviewLink;
  final String? ssnLast4;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;

  factory MembershipClientModel.fromJson(Map<String, dynamic> json) {
    final clientType = json['clientType']?.toString();
    final isGroup = clientType?.trim().toUpperCase() == 'GROUP';

    final nameRaw = json['name'];
    String? firstName;
    String? middleName;
    String? lastName;
    String? companyName;

    if (nameRaw is Map) {
      final name = Map<String, dynamic>.from(nameRaw);
      if (isGroup || name.containsKey('companyName')) {
        companyName = name['companyName']?.toString();
        firstName = name['contactFirstName']?.toString();
        lastName = name['contactLastName']?.toString();
      } else {
        firstName = name['firstName']?.toString();
        middleName = name['middleName']?.toString();
        lastName = name['lastName']?.toString();
      }
    } else if (nameRaw is String) {
      if (isGroup) {
        companyName = nameRaw.trim();
      } else {
        final parts = nameRaw.trim().split(RegExp(r'\s+'));
        firstName = parts.isNotEmpty ? parts.first : null;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      }
    }

    final contactRaw = json['contact'];
    final contact = contactRaw is Map
        ? Map<String, dynamic>.from(contactRaw)
        : const <String, dynamic>{};

    final addressRaw = json['address'];
    final address = addressRaw is Map
        ? Map<String, dynamic>.from(addressRaw)
        : const <String, dynamic>{};

    final metadataRaw = json['metadata'];
    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : const <String, dynamic>{};

    return MembershipClientModel(
      id: json['id']?.toString() ?? '',
      clientType: clientType,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      companyName: companyName,
      email: contact['email']?.toString(),
      phoneNumber:
          contact['phoneNumber']?.toString() ??
          contact['cellPhone']?.toString() ??
          contact['phone']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
      ssnLast4: metadata['ssnLast4']?.toString(),
      addressLine1: address['addressLine1']?.toString(),
      addressLine2: address['addressLine2']?.toString(),
      city: address['city']?.toString(),
      state: address['state']?.toString(),
      zipCode:
          address['zipCode']?.toString() ?? address['postalCode']?.toString(),
    );
  }
}

/// Raw `offering` / `offeringDetails` block on an enrollment record.
class MembershipOfferingModel {
  const MembershipOfferingModel({
    this.id,
    this.name,
    this.fee,
    this.registrationFee,
    this.offeringType,
    this.billingModel,
    this.billingInterval,
    this.startDate,
    this.endDate,
  });

  final String? id;
  final String? name;
  final String? fee;
  final String? registrationFee;
  final String? offeringType;
  final String? billingModel;
  final String? billingInterval;
  final String? startDate;
  final String? endDate;

  bool get isEmpty =>
      (id == null || id!.trim().isEmpty) &&
      (name == null || name!.trim().isEmpty);

  factory MembershipOfferingModel.fromJson(Map<String, dynamic> json) {
    return MembershipOfferingModel(
      id: json['id']?.toString() ?? json['offeringId']?.toString(),
      name: json['name']?.toString() ?? json['offeringName']?.toString(),
      fee: json['fee']?.toString(),
      registrationFee: json['registrationFee']?.toString(),
      offeringType: json['offeringType']?.toString(),
      billingModel: json['billingModel']?.toString(),
      billingInterval: json['billingInterval']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }
}

/// Enrollment record from `GET /enrollments`, `GET /enrollments/:id`, and the
/// associated/relevant membership endpoints.
class PendingMembershipModel {
  const PendingMembershipModel({
    required this.id,
    this.clientId,
    this.status,
    this.enrollmentType,
    this.enrollmentDisplayLabel,
    this.relationshipToPrimary,
    this.startDate,
    this.endDate,
    this.offeringId,
    this.offering,
    this.client,
    this.note,
    this.createdAt,
  });

  final String id;
  final String? clientId;
  final String? status;
  final String? enrollmentType;
  final String? enrollmentDisplayLabel;
  final String? relationshipToPrimary;
  final String? startDate;
  final String? endDate;
  final String? offeringId;
  final MembershipOfferingModel? offering;
  final MembershipClientModel? client;
  final String? note;
  final String? createdAt;

  factory PendingMembershipModel.fromJson(Map<String, dynamic> json) {
    final offeringRaw = json['offering'];
    final offeringDetailsRaw = json['offeringDetails'];

    MembershipOfferingModel? offering;
    if (offeringRaw is Map) {
      final parsed = MembershipOfferingModel.fromJson(
        Map<String, dynamic>.from(offeringRaw),
      );
      if (!parsed.isEmpty) offering = parsed;
    }
    if (offering == null && offeringDetailsRaw is Map) {
      final parsed = MembershipOfferingModel.fromJson(
        Map<String, dynamic>.from(offeringDetailsRaw),
      );
      if (!parsed.isEmpty) offering = parsed;
    }

    return PendingMembershipModel(
      id: json['id']?.toString() ?? '',
      clientId: json['clientId']?.toString(),
      status: json['status']?.toString(),
      enrollmentType: json['enrollmentType']?.toString(),
      enrollmentDisplayLabel: json['enrollmentDisplayLabel']?.toString(),
      relationshipToPrimary: json['relationshipToPrimary']?.toString(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      offeringId: json['offeringId']?.toString(),
      offering: offering,
      client: json['client'] is Map
          ? MembershipClientModel.fromJson(
              Map<String, dynamic>.from(json['client'] as Map),
            )
          : null,
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// `GET /enrollments/associate-membership/:clientId` payload.
class MembershipAssociatedResultModel {
  const MembershipAssociatedResultModel({
    required this.clientId,
    required this.details,
    required this.totalGroup,
  });

  final String clientId;
  final List<PendingMembershipModel> details;
  final int totalGroup;

  factory MembershipAssociatedResultModel.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    final total = json['totalGroup'];

    return MembershipAssociatedResultModel(
      clientId: json['clientId']?.toString() ?? '',
      details: details is List
          ? details
                .whereType<Map>()
                .map(
                  (item) => PendingMembershipModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      totalGroup: total is num
          ? total.toInt()
          : int.tryParse(total?.toString() ?? '') ?? 0,
    );
  }
}
