class AuthMeModel {
  const AuthMeModel({
    required this.user,
    this.menu = const [],
    this.agentProfile,
    this.clientProfile,
  });

  final AuthMeUserModel user;
  final List<String> menu;
  final AuthMeAgentProfileModel? agentProfile;
  final AuthMeClientProfileModel? clientProfile;

  factory AuthMeModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final menuRaw = json['menu'];
    final agentProfileRaw = json['agentProfile'];
    final clientProfileRaw = json['clientProfile'];

    return AuthMeModel(
      user: userRaw is Map<String, dynamic>
          ? AuthMeUserModel.fromJson(userRaw)
          : const AuthMeUserModel(),
      menu: menuRaw is List
          ? menuRaw.whereType<String>().toList()
          : const [],
      agentProfile: agentProfileRaw is Map<String, dynamic>
          ? AuthMeAgentProfileModel.fromJson(agentProfileRaw)
          : null,
      clientProfile: clientProfileRaw is Map<String, dynamic>
          ? AuthMeClientProfileModel.fromJson(clientProfileRaw)
          : null,
    );
  }
}

class AuthMeAddressModel {
  const AuthMeAddressModel({
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  factory AuthMeAddressModel.fromJson(Map<String, dynamic> json) {
    return AuthMeAddressModel(
      addressLine1: json['addressLine1'] as String?,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }
}

class AuthMeAgencyGroupModel {
  const AuthMeAgencyGroupModel({
    this.id,
    this.name,
  });

  final String? id;
  final String? name;

  factory AuthMeAgencyGroupModel.fromJson(Map<String, dynamic> json) {
    return AuthMeAgencyGroupModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }
}

class AuthMeProfileFileModel {
  const AuthMeProfileFileModel({
    this.id,
    this.name,
    this.url,
  });

  final String? id;
  final String? name;
  final String? url;

  factory AuthMeProfileFileModel.fromJson(Map<String, dynamic> json) {
    return AuthMeProfileFileModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      url: json['url'] as String?,
    );
  }
}

class AuthMeAgentProfileModel {
  const AuthMeAgentProfileModel({
    this.id,
    this.userId,
    this.email,
    this.firstName,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.profileId,
    this.profileFile,
    this.profilePreviewLink,
    this.referralLink,
    this.agentCode,
    this.clientCode,
    this.agencyGroup,
    this.status,
    this.address,
  });

  final String? id;
  final String? userId;
  final String? email;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? profileId;
  final AuthMeProfileFileModel? profileFile;
  final String? profilePreviewLink;
  final String? referralLink;
  final String? agentCode;
  final String? clientCode;
  final AuthMeAgencyGroupModel? agencyGroup;
  final String? status;
  final AuthMeAddressModel? address;

  factory AuthMeAgentProfileModel.fromJson(Map<String, dynamic> json) {
    final addressRaw = json['address'];
    final agencyGroupRaw = json['agencyGroup'];
    final profileFileRaw = json['profileFile'];

    return AuthMeAgentProfileModel(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profileId: json['profileId'] as String?,
      profileFile: profileFileRaw is Map<String, dynamic>
          ? AuthMeProfileFileModel.fromJson(profileFileRaw)
          : null,
      profilePreviewLink: _optionalString(json['profilePreviewLink']),
      referralLink: _optionalString(json['referralLink']),
      agentCode: json['agentCode'] as String?,
      clientCode: json['clientCode'] as String?,
      agencyGroup: _parseAgencyGroup(agencyGroupRaw),
      status: json['status'] as String?,
      address: addressRaw is Map<String, dynamic>
          ? AuthMeAddressModel.fromJson(addressRaw)
          : null,
    );
  }
}

class AuthMeClientProfileModel {
  const AuthMeClientProfileModel({
    this.profilePreviewLink,
    this.referralLink,
  });

  final String? profilePreviewLink;
  final String? referralLink;

  factory AuthMeClientProfileModel.fromJson(Map<String, dynamic> json) {
    return AuthMeClientProfileModel(
      profilePreviewLink: _optionalString(json['profilePreviewLink']),
      referralLink: _optionalString(json['referralLink']),
    );
  }
}

class AuthMeUserModel {
  const AuthMeUserModel({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.email,
    this.phoneNumber,
    this.emailVerifiedAt,
    this.status,
    this.profileImage,
    this.profilePreviewLink,
    this.mfaEnabled,
    this.userType,
    this.createdAt,
    this.updatedAt,
    this.agencyGroupId,
    this.agencyGroupName,
    this.currentTenant,
    this.currentRoles = const [],
    this.tenantAssociations = const [],
  });

  final String? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? email;
  final String? phoneNumber;
  final String? emailVerifiedAt;
  final String? status;
  final String? profileImage;
  final String? profilePreviewLink;
  final bool? mfaEnabled;
  final String? userType;
  final String? createdAt;
  final String? updatedAt;
  final String? agencyGroupId;
  final String? agencyGroupName;
  final AuthMeTenantModel? currentTenant;
  final List<String> currentRoles;
  final List<AuthMeTenantAssociationModel> tenantAssociations;

  factory AuthMeUserModel.fromJson(Map<String, dynamic> json) {
    final currentTenantRaw = json['currentTenant'];
    final currentRolesRaw = json['currentRoles'];
    final tenantAssociationsRaw = json['tenantAssociations'];

    return AuthMeUserModel(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
      status: json['status'] as String?,
      profileImage: _optionalString(json['profileImage']),
      profilePreviewLink: _optionalString(json['profilePreviewLink']),
      mfaEnabled: json['mfaEnabled'] as bool?,
      userType: json['userType'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      agencyGroupId: _optionalString(json['agencyGroupId']),
      agencyGroupName: _optionalString(json['agencyGroupName']),
      currentTenant: currentTenantRaw is Map<String, dynamic>
          ? AuthMeTenantModel.fromJson(currentTenantRaw)
          : null,
      currentRoles: currentRolesRaw is List
          ? currentRolesRaw.whereType<String>().toList()
          : const [],
      tenantAssociations: tenantAssociationsRaw is List
          ? tenantAssociationsRaw
              .whereType<Map<String, dynamic>>()
              .map(AuthMeTenantAssociationModel.fromJson)
              .toList()
          : const [],
    );
  }
}

class AuthMeTenantModel {
  const AuthMeTenantModel({
    this.id,
    this.slug,
    this.name,
  });

  final String? id;
  final String? slug;
  final String? name;

  factory AuthMeTenantModel.fromJson(Map<String, dynamic> json) {
    return AuthMeTenantModel(
      id: json['id'] as String?,
      slug: json['slug'] as String?,
      name: json['name'] as String?,
    );
  }
}

class AuthMeTenantAssociationModel {
  const AuthMeTenantAssociationModel({
    this.tenantId,
    this.tenantSlug,
    this.tenantName,
    this.roles = const [],
    this.branchIds = const [],
    this.isActive,
    this.ssoProvider,
    this.ssoUserId,
  });

  final String? tenantId;
  final String? tenantSlug;
  final String? tenantName;
  final List<String> roles;
  final List<String> branchIds;
  final bool? isActive;
  final String? ssoProvider;
  final String? ssoUserId;

  factory AuthMeTenantAssociationModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final branchIdsRaw = json['branchIds'];

    return AuthMeTenantAssociationModel(
      tenantId: json['tenantId'] as String?,
      tenantSlug: json['tenantSlug'] as String?,
      tenantName: json['tenantName'] as String?,
      roles: rolesRaw is List
          ? rolesRaw.whereType<String>().toList()
          : const [],
      branchIds: branchIdsRaw is List
          ? branchIdsRaw.map((id) => id.toString()).toList()
          : const [],
      isActive: json['isActive'] as bool?,
      ssoProvider: json['ssoProvider'] as String?,
      ssoUserId: json['ssoUserId'] as String?,
    );
  }
}

String? _optionalString(dynamic value) {
  if (value == null) {
    return null;
  }

  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Accepts either a nested `{ id, name }` object or a bare agency group id string.
AuthMeAgencyGroupModel? _parseAgencyGroup(dynamic value) {
  if (value is Map<String, dynamic>) {
    return AuthMeAgencyGroupModel.fromJson(value);
  }

  final id = _optionalString(value);
  if (id == null) {
    return null;
  }

  return AuthMeAgencyGroupModel(id: id);
}
