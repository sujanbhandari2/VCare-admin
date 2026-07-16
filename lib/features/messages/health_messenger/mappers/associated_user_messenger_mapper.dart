import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

class AssociatedUserMessengerMapper {
  const AssociatedUserMessengerMapper._();

  static List<MessengerUser> toMessengerUsers(List<AssociatedUser> users) {
    return users.map(toMessengerUser).toList(growable: false);
  }

  static MessengerUser toMessengerUser(AssociatedUser user) {
    return MessengerUser(
      id: user.id,
      username: user.displayName,
      roleLabel: humanizeRole(user.role),
      email: user.email,
      isOnline: false,
      avatarUrl: user.profileImage,
    );
  }

  static ChatUserRegistrationBody toRegistrationBody(
    AssociatedUser user, {
    required String externalTenantId,
  }) {
    return ChatUserRegistrationBody.resolve(
      externalTenantId: externalTenantId,
      externalUserId: user.id,
      externalUserRole: user.role.trim().isEmpty
          ? HealthMessengerBootstrapConfig.defaultExternalUserRole
          : user.role.trim().toLowerCase(),
      email: user.email.trim().isEmpty ? null : user.email.trim(),
      name: user.displayName.trim().isEmpty ? null : user.displayName.trim(),
      profile: user.profileImage?.trim().isEmpty ?? true
          ? null
          : user.profileImage!.trim(),
    );
  }

  static ChatUserRegistrationBody registrationBodyForSignedInUser(
    HealthMessengerBootstrapConfig config,
  ) {
    return ChatUserRegistrationBody.resolve(
      externalTenantId: config.externalTenantId,
      externalUserId: config.externalUserId,
      externalUserRole: config.externalUserRole,
      email: config.email.trim().isEmpty ? null : config.email.trim(),
      name: config.displayName.trim().isEmpty ? null : config.displayName.trim(),
      profile: config.profile?.trim().isEmpty ?? true
          ? null
          : config.profile!.trim(),
    );
  }

  static String humanizeRole(String role) {
    final trimmed = role.trim();
    if (trimmed.isEmpty) {
      return 'User';
    }
    return trimmed
        .toLowerCase()
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
