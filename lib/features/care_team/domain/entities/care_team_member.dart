enum CareTeamRole {
  advocate,
  agent,
  customerSupport,
  provider,
  employer,
  insurance,
}

class CareTeamMember {
  const CareTeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.roleTitle,
    this.photoAsset,
    this.photoUrl,
    this.logoText,
    this.bio,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.hours,
    this.policyNumber,
    this.groupNumber,
    this.profileId,
    this.userId,
    this.agentId,
  });

  final String id;
  final String name;
  final CareTeamRole role;

  /// Free-form role label from the API (e.g. "Primary Care Physician").
  final String? roleTitle;
  final String? photoAsset;
  final String? photoUrl;
  final String? logoText;
  final String? bio;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? hours;
  final String? policyNumber;
  final String? groupNumber;
  final String? profileId;

  /// Peer user id for messaging; omit Message action when missing.
  final String? userId;

  /// Set for agent-owned contacts; null/empty for org-scoped listed members.
  final String? agentId;

  String get roleLabel {
    final title = roleTitle?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    switch (role) {
      case CareTeamRole.advocate:
        return 'Advocate';
      case CareTeamRole.agent:
        return 'Agent';
      case CareTeamRole.customerSupport:
        return 'Customer Support';
      case CareTeamRole.provider:
        return 'Provider';
      case CareTeamRole.employer:
        return 'Employer';
      case CareTeamRole.insurance:
        return 'Insurance';
    }
  }

  /// Card eyebrow: "Your advocate" for Advocate, otherwise the display role.
  String get cardRoleLabel {
    final label = roleLabel.trim();
    if (label.toLowerCase() == 'advocate') {
      return 'Your advocate';
    }
    return label;
  }

  bool get isOrg =>
      role == CareTeamRole.employer || role == CareTeamRole.insurance;

  bool get isAgentOwned {
    final id = agentId?.trim();
    return id != null && id.isNotEmpty;
  }

  bool get canMessage {
    final id = userId?.trim();
    return id != null && id.isNotEmpty;
  }

  CareTeamMember copyWith({
    String? id,
    String? name,
    CareTeamRole? role,
    String? roleTitle,
    String? photoAsset,
    String? photoUrl,
    String? logoText,
    String? bio,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? hours,
    String? policyNumber,
    String? groupNumber,
    String? profileId,
    String? userId,
    String? agentId,
    bool clearRoleTitle = false,
    bool clearPhotoAsset = false,
    bool clearPhotoUrl = false,
    bool clearLogoText = false,
    bool clearBio = false,
    bool clearEmail = false,
    bool clearPhone = false,
    bool clearWebsite = false,
    bool clearAddress = false,
    bool clearHours = false,
    bool clearPolicyNumber = false,
    bool clearGroupNumber = false,
    bool clearProfileId = false,
    bool clearUserId = false,
    bool clearAgentId = false,
  }) {
    return CareTeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      roleTitle: clearRoleTitle ? null : (roleTitle ?? this.roleTitle),
      photoAsset: clearPhotoAsset ? null : (photoAsset ?? this.photoAsset),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      logoText: clearLogoText ? null : (logoText ?? this.logoText),
      bio: clearBio ? null : (bio ?? this.bio),
      email: clearEmail ? null : (email ?? this.email),
      phone: clearPhone ? null : (phone ?? this.phone),
      website: clearWebsite ? null : (website ?? this.website),
      address: clearAddress ? null : (address ?? this.address),
      hours: clearHours ? null : (hours ?? this.hours),
      policyNumber:
          clearPolicyNumber ? null : (policyNumber ?? this.policyNumber),
      groupNumber: clearGroupNumber ? null : (groupNumber ?? this.groupNumber),
      profileId: clearProfileId ? null : (profileId ?? this.profileId),
      userId: clearUserId ? null : (userId ?? this.userId),
      agentId: clearAgentId ? null : (agentId ?? this.agentId),
    );
  }
}
