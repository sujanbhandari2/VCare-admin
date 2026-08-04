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

extension AuthMeAddressMapper on model.AuthMeAddressModel {
  AuthMeAddress toEntity() {
    return AuthMeAddress(
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
    );
  }
}

extension AuthMeAgencyGroupMapper on model.AuthMeAgencyGroupModel {
  AuthMeAgencyGroup toEntity() {
    return AuthMeAgencyGroup(
      id: id,
      name: name,
    );
  }
}

extension AuthMeProfileFileMapper on model.AuthMeProfileFileModel {
  AuthMeProfileFile toEntity() {
    return AuthMeProfileFile(
      id: id,
      name: name,
      url: url,
    );
  }
}

extension AuthMeAgentProfileMapper on model.AuthMeAgentProfileModel {
  AuthMeAgentProfile toEntity() {
    return AuthMeAgentProfile(
      id: id,
      userId: userId,
      email: email,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phoneNumber: phoneNumber,
      profileId: profileId,
      profileFile: profileFile?.toEntity(),
      profilePreviewLink: profilePreviewLink,
      referralLink: referralLink,
      agentCode: agentCode,
      clientCode: clientCode,
      agencyGroup: agencyGroup?.toEntity(),
      status: status,
      address: address?.toEntity(),
      bio: bio,
      allowTextNotification: allowTextNotification,
      primaryCity: primaryCity,
      primaryState: primaryState,
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
      agencyGroupId: agencyGroupId,
      agencyGroupName: agencyGroupName,
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
