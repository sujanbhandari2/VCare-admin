import 'package:vcare_admin/core/services/image/stable_image_cache_key.dart';

/// Current authenticated user profile returned by `GET auth/me`.
class AuthMe {
  const AuthMe({
    required this.user,
    this.menu = const [],
    this.agentProfile,
    this.clientProfile,
  });

  final AuthMeUser user;
  final List<String> menu;
  final AuthMeAgentProfile? agentProfile;
  final AuthMeClientProfile? clientProfile;

  /// Best available profile photo URL from user or nested profile payloads.
  String? get profilePhotoUrl {
    final fromUser = user.profilePhotoUrl;
    if (fromUser != null) {
      return fromUser;
    }

    final agentPreview = agentProfile?.profilePreviewLink?.trim();
    if (agentPreview != null && agentPreview.isNotEmpty) {
      return agentPreview;
    }

    final clientPreview = clientProfile?.profilePreviewLink?.trim();
    if (clientPreview != null && clientPreview.isNotEmpty) {
      return clientPreview;
    }

    return null;
  }

  /// Stable cache key for [profilePhotoUrl], which may be a rotating signed URL.
  String? get profilePhotoCacheKey {
    return stableImageCacheKey(
      prefix: 'profile-photo',
      entityId: user.id ?? agentProfile?.profileId ?? agentProfile?.userId,
      storagePath: _profileStoragePath,
      imageUrl: profilePhotoUrl,
    );
  }

  String? get _profileStoragePath {
    final userImage = user.profileImage?.trim();
    if (userImage != null && userImage.isNotEmpty) {
      return userImage;
    }

    final agentFileUrl = agentProfile?.profileFile?.url?.trim();
    if (agentFileUrl != null && agentFileUrl.isNotEmpty) {
      return agentFileUrl;
    }

    return null;
  }

  /// Server-provided referral link from agent or client profile payloads.
  String? get referralLink {
    final agentLink = agentProfile?.referralLink?.trim();
    if (agentLink != null && agentLink.isNotEmpty) {
      return agentLink;
    }

    final clientLink = clientProfile?.referralLink?.trim();
    if (clientLink != null && clientLink.isNotEmpty) {
      return clientLink;
    }

    return null;
  }
}

/// Postal address nested under auth/me agent or client profile payloads.
class AuthMeAddress {
  const AuthMeAddress({
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
}

/// Agency group nested under auth/me agent profile payloads.
class AuthMeAgencyGroup {
  const AuthMeAgencyGroup({
    this.id,
    this.name,
  });

  final String? id;
  final String? name;
}

/// File metadata nested under auth/me agent profile payloads.
class AuthMeProfileFile {
  const AuthMeProfileFile({
    this.id,
    this.name,
    this.url,
  });

  final String? id;
  final String? name;
  final String? url;
}

/// Agent-specific profile payload nested under auth/me for agent users.
class AuthMeAgentProfile {
  const AuthMeAgentProfile({
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
  final AuthMeProfileFile? profileFile;
  final String? profilePreviewLink;
  final String? referralLink;
  final String? agentCode;
  final String? clientCode;
  final AuthMeAgencyGroup? agencyGroup;
  final String? status;
  final AuthMeAddress? address;

  String get displayName {
    final parts = [firstName, middleName, lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .toList();
    return parts.join(' ');
  }
}

/// Client-specific profile payload nested under auth/me for client users.
class AuthMeClientProfile {
  const AuthMeClientProfile({
    this.profilePreviewLink,
    this.referralLink,
  });

  final String? profilePreviewLink;
  final String? referralLink;
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

  /// Profile photo URL from preview link or legacy profile image field.
  String? get profilePhotoUrl {
    final preview = profilePreviewLink?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview;
    }

    final image = profileImage?.trim();
    if (image != null && image.isNotEmpty) {
      return image;
    }

    return null;
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
