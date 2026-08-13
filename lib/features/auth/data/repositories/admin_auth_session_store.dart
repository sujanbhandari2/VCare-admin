import 'dart:convert';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/auth/data/models/admin_login_result_model.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/app_urls.dart';

class AdminAuthSessionStore {
  const AdminAuthSessionStore(this._storage);

  final StorageService _storage;

  Future<void> saveSession(AdminAuthSession session) async {
    await _storage.set(StorageKeys.loggedInUserToken, session.accessToken);
    await _storage.set(
      StorageKeys.loggedInUserRefreshToken,
      session.refreshToken,
    );
    await _storage.set(
      StorageKeys.loggedInUserProfileId,
      session.user.id,
    );
    // Same value web uses as identify `externalUserId` — available before auth/me.
    await _storage.set(
      StorageKeys.loggedInUserUuid,
      session.user.id,
    );
    await _storage.set(
      StorageKeys.loggedInUserTenantId,
      session.user.currentTenant.id,
    );
    await _storage.set(StorageKeys.loggedInUserEmail, session.user.email);
    await _storage.set(
      StorageKeys.loggedInUserUsername,
      session.user.displayName,
    );
    await _storage.set(
      StorageKeys.authTenantSlug,
      session.user.currentTenant.slug,
    );
    await _storage.set(
      StorageKeys.authUser,
      jsonEncode(_userToJson(session.user)),
    );
    await _storage.set(
      StorageKeys.authMenu,
      jsonEncode(session.menu),
    );
    if (session.urls != null) {
      await _storage.set(
        StorageKeys.authUrls,
        jsonEncode(_urlsToJson(session.urls!)),
      );
    } else {
      await _storage.remove(StorageKeys.authUrls);
    }
    await _storage.set(
      StorageKeys.tokenRefreshedDate,
      DateTime.now().toIso8601String(),
    );
  }

  AdminAuthSession? readSession() {
    final accessToken =
        _storage.get(StorageKeys.loggedInUserToken)?.toString() ?? '';
    final refreshToken =
        _storage.get(StorageKeys.loggedInUserRefreshToken)?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      return null;
    }

    final user = _readUser();
    if (user == null) {
      return null;
    }

    return AdminAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      menu: _readMenu(),
      urls: _readUrls(),
    );
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.set(StorageKeys.loggedInUserToken, accessToken);
    await _storage.set(StorageKeys.loggedInUserRefreshToken, refreshToken);
    await _storage.set(
      StorageKeys.tokenRefreshedDate,
      DateTime.now().toIso8601String(),
    );
  }

  /// Patches persisted auth user fields after a self-service profile update.
  Future<void> patchUser(AdminAuthUser user) async {
    await _storage.set(StorageKeys.loggedInUserProfileId, user.id);
    await _storage.set(StorageKeys.loggedInUserUuid, user.id);
    await _storage.set(StorageKeys.loggedInUserTenantId, user.currentTenant.id);
    await _storage.set(StorageKeys.loggedInUserEmail, user.email);
    await _storage.set(StorageKeys.loggedInUserUsername, user.displayName);
    await _storage.set(StorageKeys.authTenantSlug, user.currentTenant.slug);
    await _storage.set(StorageKeys.authUser, jsonEncode(_userToJson(user)));
  }

  Future<void> clearSession() async {
    for (final key in adminSessionStorageKeys) {
      await _storage.remove(key);
    }
  }

  static const adminSessionStorageKeys = <String>[
    StorageKeys.loggedInUserToken,
    StorageKeys.loggedInUserRefreshToken,
    StorageKeys.loggedInUserProfileId,
    StorageKeys.loggedInUserUuid,
    StorageKeys.loggedInUserTenantId,
    StorageKeys.loggedInUserEmail,
    StorageKeys.loggedInUserUsername,
    StorageKeys.authUser,
    StorageKeys.authMenu,
    StorageKeys.authUrls,
    StorageKeys.authTenantSlug,
    StorageKeys.tokenRefreshedDate,
  ];

  AdminAuthUser? _readUser() {
    final raw = _storage.get(StorageKeys.authUser)?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return AdminAuthUserModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  List<String> _readMenu() {
    final raw = _storage.get(StorageKeys.authMenu)?.toString();
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final json = jsonDecode(raw);
      if (json is! List) {
        return const [];
      }
      return json.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  AppUrls? _readUrls() {
    final raw = _storage.get(StorageKeys.authUrls)?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return AppUrlsModel.fromJson(json).toEntity();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _userToJson(AdminAuthUser user) {
    return AdminAuthUserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      currentTenant: AdminAuthTenantModel(
        id: user.currentTenant.id,
        slug: user.currentTenant.slug,
        name: user.currentTenant.name,
      ),
      currentRoles: user.currentRoles,
    ).toJson();
  }

  Map<String, dynamic> _urlsToJson(AppUrls urls) {
    return AppUrlsModel(
      portal: urls.portal,
      client: urls.client,
      agent: urls.agent,
      landing: urls.landing,
    ).toJson();
  }
}
