import 'package:vcare_admin/features/profile/data/models/auth_me_model.dart' as model;
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';

extension AuthMeMapper on model.AuthMeModel {
  AuthMe toEntity() {
    return AuthMe(
      user: user.toEntity(),
      menu: menu,
      agentProfile: agentProfile?.toEntity(),
      clientProfile: clientProfile?.toEntity(),
    );
  }
}

extension AuthMeAgentProfileMapper on model.AuthMeAgentProfileModel {
  AuthMeAgentProfile toEntity() {
    return AuthMeAgentProfile(
      profilePreviewLink: profilePreviewLink,
      referralLink: referralLink,
    );
  }
}

extension AuthMeClientProfileMapper on model.AuthMeClientProfileModel {
  AuthMeClientProfile toEntity() {
    return AuthMeClientProfile(
      profilePreviewLink: profilePreviewLink,
      referralLink: referralLink,
    );
  }
}

extension AuthMeUserMapper on model.AuthMeUserModel {
  AuthMeUser toEntity() {
    return AuthMeUser(
      id: id,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      email: email,
      phoneNumber: phoneNumber,
      emailVerifiedAt: emailVerifiedAt,
      status: status,
      profileImage: profileImage,
      profilePreviewLink: profilePreviewLink,
      mfaEnabled: mfaEnabled,
      userType: userType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      currentTenant: currentTenant?.toEntity(),
      currentRoles: currentRoles,
      tenantAssociations:
          tenantAssociations.map((association) => association.toEntity()).toList(),
    );
  }
}

extension AuthMeTenantMapper on model.AuthMeTenantModel {
  AuthMeTenant toEntity() {
    return AuthMeTenant(
      id: id,
      slug: slug,
      name: name,
    );
  }
}

extension AuthMeTenantAssociationMapper on model.AuthMeTenantAssociationModel {
  AuthMeTenantAssociation toEntity() {
    return AuthMeTenantAssociation(
      tenantId: tenantId,
      tenantSlug: tenantSlug,
      tenantName: tenantName,
      roles: roles,
      branchIds: branchIds,
      isActive: isActive,
      ssoProvider: ssoProvider,
      ssoUserId: ssoUserId,
    );
  }
}
