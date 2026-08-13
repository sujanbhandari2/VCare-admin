/// Nested person on a referral case (assignee / creator / createdBy object).
class ReferralCasePersonModel {
  const ReferralCasePersonModel({
    this.id,
    this.fullName = '',
    this.email,
  });

  final String? id;
  final String fullName;
  final String? email;

  /// Parses a person that may be a plain string id or `{id, fullName, email}`.
  static ReferralCasePersonModel? parse(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return ReferralCasePersonModel(id: trimmed, fullName: '');
    }

    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      final id = _optionalString(json['id']);
      final fullName = _optionalString(json['fullName']) ?? '';
      final email = _optionalString(json['email']);
      if (id == null && fullName.isEmpty && email == null) return null;
      return ReferralCasePersonModel(
        id: id,
        fullName: fullName,
        email: email,
      );
    }

    return null;
  }
}

class ReferralCaseClientContactModel {
  const ReferralCaseClientContactModel({
    this.email,
    this.phoneNumber,
    this.cellPhone,
    this.phone,
    this.firstName,
    this.lastName,
  });

  final String? email;
  final String? phoneNumber;
  final String? cellPhone;
  final String? phone;
  final String? firstName;
  final String? lastName;

  factory ReferralCaseClientContactModel.fromJson(Map<String, dynamic> json) {
    return ReferralCaseClientContactModel(
      email: _optionalString(json['email']),
      phoneNumber: _optionalString(json['phoneNumber']),
      cellPhone: _optionalString(json['cellPhone']),
      phone: _optionalString(json['phone']),
      firstName: _optionalString(json['firstName']),
      lastName: _optionalString(json['lastName']),
    );
  }

  String get resolvedPhone {
    return phoneNumber ?? cellPhone ?? phone ?? '';
  }
}

class ReferralCaseClientNameModel {
  const ReferralCaseClientNameModel({
    this.firstName,
    this.middleName,
    this.lastName,
    this.companyName,
    this.contactFirstName,
    this.contactLastName,
  });

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? companyName;
  final String? contactFirstName;
  final String? contactLastName;

  factory ReferralCaseClientNameModel.fromJson(Map<String, dynamic> json) {
    return ReferralCaseClientNameModel(
      firstName: _optionalString(json['firstName']),
      middleName: _optionalString(json['middleName']),
      lastName: _optionalString(json['lastName']),
      companyName: _optionalString(json['companyName']),
      contactFirstName: _optionalString(json['contactFirstName']),
      contactLastName: _optionalString(json['contactLastName']),
    );
  }
}

class ReferralCaseClientModel {
  const ReferralCaseClientModel({
    required this.id,
    this.clientType,
    this.companyName,
    this.contactFirstName,
    this.contactLastName,
    this.name,
    this.dateOfBirth,
    this.contact,
    this.address,
    this.profilePreviewLink,
    this.bloodType,
    this.dependentOf,
    this.membershipPlan,
    this.avatarUrl,
  });

  final String id;
  final String? clientType;
  final String? companyName;
  final String? contactFirstName;
  final String? contactLastName;
  final ReferralCaseClientNameModel? name;
  final String? dateOfBirth;
  final ReferralCaseClientContactModel? contact;
  final Map<String, dynamic>? address;
  final String? profilePreviewLink;
  final String? bloodType;
  final String? dependentOf;
  final String? membershipPlan;
  final String? avatarUrl;

  factory ReferralCaseClientModel.fromJson(Map<String, dynamic> json) {
    final nameRaw = json['name'];
    final contactRaw = json['contact'];
    final addressRaw = json['address'];

    return ReferralCaseClientModel(
      id: json['id']?.toString() ?? '',
      clientType: _optionalString(json['clientType']),
      companyName: _optionalString(json['companyName']),
      contactFirstName: _optionalString(json['contactFirstName']),
      contactLastName: _optionalString(json['contactLastName']),
      name: nameRaw is Map
          ? ReferralCaseClientNameModel.fromJson(
              Map<String, dynamic>.from(nameRaw),
            )
          : null,
      dateOfBirth: _optionalString(json['dateOfBirth']),
      contact: contactRaw is Map
          ? ReferralCaseClientContactModel.fromJson(
              Map<String, dynamic>.from(contactRaw),
            )
          : null,
      address: addressRaw is Map
          ? Map<String, dynamic>.from(addressRaw)
          : null,
      profilePreviewLink: _optionalString(
        json['profilePreviewLink'] ?? json['profile_preview_link'],
      ),
      bloodType: _optionalString(json['bloodType']),
      dependentOf: _optionalString(json['dependentOf']),
      membershipPlan: _optionalString(json['membershipPlan']),
      avatarUrl: _optionalString(json['avatarUrl'] ?? json['profileImage']),
    );
  }
}

/// API shape for `ApiReferralCaseRecord` / detail.
class ReferralCaseModel {
  const ReferralCaseModel({
    required this.id,
    required this.clientId,
    this.tenantId,
    this.status,
    this.type,
    this.priority,
    this.assignedTo,
    this.sponsorId,
    this.sponsorType,
    this.clonedFromCaseId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.client,
    this.assignee,
    this.creator,
    this.isBookmarked = false,
    this.title,
    this.description,
    this.caseNumber,
  });

  final String id;
  final String? tenantId;
  final String? status;
  final String? type;
  final String? priority;
  final String? assignedTo;
  final String clientId;
  final String? sponsorId;
  final String? sponsorType;
  final String? clonedFromCaseId;
  final String? createdAt;
  final String? updatedAt;
  final ReferralCasePersonModel? createdBy;
  final ReferralCasePersonModel? updatedBy;
  final ReferralCaseClientModel? client;
  final ReferralCasePersonModel? assignee;
  final ReferralCasePersonModel? creator;
  final bool isBookmarked;
  final String? title;
  final String? description;
  final String? caseNumber;

  factory ReferralCaseModel.fromJson(Map<String, dynamic> json) {
    final clientRaw = json['client'];

    return ReferralCaseModel(
      id: json['id']?.toString() ?? '',
      tenantId: _optionalString(json['tenantId']),
      status: _optionalString(json['status']),
      type: _optionalString(json['type']),
      priority: _optionalString(json['priority']),
      assignedTo: _optionalString(json['assignedTo']),
      clientId: json['clientId']?.toString() ?? '',
      sponsorId: _optionalString(json['sponsorId']),
      sponsorType: _optionalString(json['sponsorType']),
      clonedFromCaseId: _optionalString(json['clonedFromCaseId']),
      createdAt: _optionalString(json['createdAt']),
      updatedAt: _optionalString(json['updatedAt']),
      createdBy: ReferralCasePersonModel.parse(json['createdBy']),
      updatedBy: ReferralCasePersonModel.parse(json['updatedBy']),
      client: clientRaw is Map
          ? ReferralCaseClientModel.fromJson(
              Map<String, dynamic>.from(clientRaw),
            )
          : null,
      assignee: ReferralCasePersonModel.parse(json['assignee']),
      creator: ReferralCasePersonModel.parse(json['creator']),
      isBookmarked: json['isBookmarked'] == true,
      title: _optionalString(json['title']),
      description: _optionalString(json['description']),
      caseNumber: _optionalString(json['caseNumber']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
