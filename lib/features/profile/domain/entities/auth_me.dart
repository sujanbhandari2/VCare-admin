/// Current authenticated user profile returned by `GET auth/me`.
class AuthMe {
  const AuthMe({
    required this.user,
    this.menu = const [],
  });

  final AuthMeUser user;
  final List<String> menu;
}

/// User identity and tenant context from the auth/me endpoint.
class AuthMeUser {
  const AuthMeUser({
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
  final bool? mfaEnabled;
  final String? userType;
  final String? createdAt;
  final String? updatedAt;
  final AuthMeTenant? currentTenant;
  final List<String> currentRoles;
  final List<AuthMeTenantAssociation> tenantAssociations;

  /// Full display name built from first, middle, and last name.
  String get displayName {
    final parts = [firstName, middleName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.join(' ');
  }
}

class AuthMeTenant {
  const AuthMeTenant({
    this.id,
    this.slug,
    this.name,
  });

  final String? id;
  final String? slug;
  final String? name;
}

class AuthMeTenantAssociation {
  const AuthMeTenantAssociation({
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
}
