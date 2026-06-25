import 'package:vcare_admin/features/profile/data/models/auth_me_model.dart' as model;
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';

extension AuthMeMapper on model.AuthMeModel {
  AuthMe toEntity() {
    return AuthMe(
      user: user.toEntity(),
      menu: menu,
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
