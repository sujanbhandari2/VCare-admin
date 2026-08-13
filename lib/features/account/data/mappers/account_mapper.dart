import 'package:vcare_admin/features/account/data/models/updated_account_user_model.dart';
import 'package:vcare_admin/features/account/domain/entities/updated_account_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';

extension UpdatedAccountUserModelMapper on UpdatedAccountUserModel {
  UpdatedAccountUser toEntity() {
    return UpdatedAccountUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      profileId: profileId,
      profilePreviewLink: profilePreviewLink,
      profileImage: profileImage,
    );
  }
}

extension UpdatedAccountUserSessionMapper on UpdatedAccountUser {
  AdminAuthUser toPatchedAuthUser(AdminAuthUser existing) {
    return AdminAuthUser(
      id: id,
      email: email,
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      currentTenant: existing.currentTenant,
      currentRoles: existing.currentRoles,
    );
  }
}

/// Whether the current tenant association uses SSO (password change unavailable).
bool isSsoAccount(AuthMeUser user) {
  final tenantId = user.currentTenant?.id?.trim();
  if (tenantId == null || tenantId.isEmpty) {
    return false;
  }

  for (final association in user.tenantAssociations) {
    if (association.tenantId == tenantId) {
      final provider = association.ssoProvider?.trim();
      return provider != null && provider.isNotEmpty;
    }
  }

  return false;
}
