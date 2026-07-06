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

class AuthMeAgentProfileModel {
  const AuthMeAgentProfileModel({
    this.profilePreviewLink,
    this.referralLink,
  });

  final String? profilePreviewLink;
  final String? referralLink;

  factory AuthMeAgentProfileModel.fromJson(Map<String, dynamic> json) {
    return AuthMeAgentProfileModel(
      profilePreviewLink: json['profilePreviewLink'] as String?,
      referralLink: json['referralLink'] as String?,
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
      profilePreviewLink: json['profilePreviewLink'] as String?,
      referralLink: json['referralLink'] as String?,
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
      profileImage: json['profileImage'] as String?,
      profilePreviewLink: json['profilePreviewLink'] as String?,
      mfaEnabled: json['mfaEnabled'] as bool?,
      userType: json['userType'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
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
