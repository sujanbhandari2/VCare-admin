import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:vcare_admin/features/messages/health_messenger/health_messenger_bootstrap_config.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

class AssociatedUserMessengerMapper {
  const AssociatedUserMessengerMapper._();

  static List<MessengerUser> toMessengerUsers(List<AssociatedUser> users) {
    return users.map(toMessengerUser).toList(growable: false);
  }

  static MessengerUser toMessengerUser(AssociatedUser user) {
    final photoUrl = user.profilePhotoUrl?.trim();
    final loadablePhoto = photoUrl != null &&
            photoUrl.isNotEmpty &&
            messengerMediaSourceIsNetwork(photoUrl)
        ? photoUrl
        : null;
    return MessengerUser(
      id: user.id,
      username: user.displayName,
      roleLabel: displayRoleFor(user),
      email: user.email,
      isOnline: false,
      avatarUrl: loadablePhoto,
    );
  }

  /// Prefer [AssociatedUser.role] when present; otherwise [AssociatedUser.userType].
  static String displayRoleFor(AssociatedUser user) {
    final role = user.role.trim();
    if (role.isNotEmpty) {
      return humanizeRole(role);
    }
    return humanizeRole(user.userType);
  }

  static ChatUserRegistrationBody toRegistrationBody(
    AssociatedUser user, {
    required String externalTenantId,
  }) {
    final photoUrl = user.profilePhotoUrl;
    return ChatUserRegistrationBody.resolve(
      externalTenantId: externalTenantId,
      externalUserId: user.id,
      externalUserRole: user.role.trim().isEmpty
          ? HealthMessengerBootstrapConfig.defaultExternalUserRole
          : user.role.trim().toLowerCase(),
      email: user.email.trim().isEmpty ? null : user.email.trim(),
      name: user.displayName.trim().isEmpty ? null : user.displayName.trim(),
      profile: photoUrl,
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
    final upper = trimmed.toUpperCase();
    if (upper == 'CLIENT' || upper == 'AGENT' || upper == 'ADMIN') {
      return upper;
    }
    return trimmed
        .toLowerCase()
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
