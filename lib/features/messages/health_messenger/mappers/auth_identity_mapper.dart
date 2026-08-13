import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';

/// Maps VCare auth storage + profile into chat bootstrap identity fields.
class AuthIdentityMapper {
  const AuthIdentityMapper({
    required this.storage,
    this.profile,
    this.sessionExternalUserId,
    this.sessionEmail,
    this.sessionDisplayName,
  });

  final StorageService storage;
  final UserProfile? profile;

  /// Prefer in-memory admin session user id (web parity with `user.id`).
  final String? sessionExternalUserId;
  final String? sessionEmail;
  final String? sessionDisplayName;

  String get externalUserId {
    final uuid = storage.get(
      StorageKeys.loggedInUserUuid,
      defaultValue: '',
    );
    if (uuid is String && uuid.trim().isNotEmpty) {
      return uuid.trim();
    }

    final fromSession = sessionExternalUserId?.trim() ?? '';
    if (fromSession.isNotEmpty) {
      return fromSession;
    }

    final profileId = storage.get(
      StorageKeys.loggedInUserProfileId,
      defaultValue: '',
    );
    if (profileId is String && profileId.trim().isNotEmpty) {
      return profileId.trim();
    }

    final legacyId = storage.get(StorageKeys.loggedInUserId);
    if (legacyId is int && legacyId > 0) {
      return legacyId.toString();
    }

    return '';
  }

  /// Current tenant id from login / auth/me (`user.currentTenant.id`).
  String get externalTenantId {
    final tenantId = storage.get(
      StorageKeys.loggedInUserTenantId,
      defaultValue: '',
    );
    if (tenantId is String && tenantId.trim().isNotEmpty) {
      return tenantId.trim();
    }
    return '';
  }

  String get email {
    final fromStorage = storage.get(
      StorageKeys.loggedInUserEmail,
      defaultValue: '',
    );
    if (fromStorage is String && fromStorage.trim().isNotEmpty) {
      return fromStorage.trim();
    }

    final fromSession = sessionEmail?.trim() ?? '';
    if (fromSession.isNotEmpty) {
      return fromSession;
    }

    return profile?.email?.trim() ?? '';
  }

  String get displayName {
    final profileName = _profileDisplayName();
    if (profileName.isNotEmpty) {
      return profileName;
    }

    final fromSession = sessionDisplayName?.trim() ?? '';
    if (fromSession.isNotEmpty) {
      return fromSession;
    }

    final username = storage.get(
      StorageKeys.loggedInUserUsername,
      defaultValue: '',
    );
    if (username is String && username.trim().isNotEmpty) {
      return username.trim();
    }

    return email;
  }

  String? get profilePicture {
    final image = profile?.image?.trim() ?? profile?.thumbnail?.trim() ?? '';
    return image.isEmpty ? null : image;
  }

  String _profileDisplayName() {
    final parts = <String?>[
      profile?.firstName,
      profile?.middleName,
      profile?.lastName,
    ]
        .where((part) => (part?.trim().isNotEmpty ?? false))
        .cast<String>()
        .toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    final username = profile?.username?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }

    return '';
  }
}
