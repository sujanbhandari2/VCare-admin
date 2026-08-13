import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/data/repositories/admin_auth_session_store.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_session.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_user.dart';
import 'package:vcare_admin/features/auth/domain/entities/app_urls.dart';

part 'admin_auth_session_provider.g.dart';

class AdminAuthSessionState {
  const AdminAuthSessionState({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.menu = const [],
    this.urls,
  });

  final String? accessToken;
  final String? refreshToken;
  final AdminAuthUser? user;
  final List<String> menu;
  final AppUrls? urls;

  bool get isAuthenticated =>
      accessToken != null && accessToken!.trim().isNotEmpty;

  bool get hasApiAccess => isAuthenticated;

  AdminAuthSessionState copyWith({
    String? accessToken,
    String? refreshToken,
    AdminAuthUser? user,
    List<String>? menu,
    AppUrls? urls,
    bool clearUrls = false,
  }) {
    return AdminAuthSessionState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      menu: menu ?? this.menu,
      urls: clearUrls ? null : urls ?? this.urls,
    );
  }
}

@Riverpod(keepAlive: true)
AdminAuthSessionStore adminAuthSessionStore(Ref ref) {
  return AdminAuthSessionStore(ref.read(storageServiceProvider));
}

@Riverpod(keepAlive: true)
class AdminAuthSessionNotifier extends _$AdminAuthSessionNotifier {
  late AdminAuthSessionStore _store;

  @override
  AdminAuthSessionState build() {
    _store = ref.read(adminAuthSessionStoreProvider);
    final session = _store.readSession();
    if (session == null) {
      return const AdminAuthSessionState();
    }

    return AdminAuthSessionState(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: session.user,
      menu: session.menu,
      urls: session.urls,
    );
  }

  Future<void> setSession(AdminAuthSession session) async {
    await _store.saveSession(session);
    if (!ref.mounted) {
      return;
    }

    state = AdminAuthSessionState(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: session.user,
      menu: session.menu,
      urls: session.urls,
    );
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _store.updateTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> patchUser(AdminAuthUser user) async {
    await _store.patchUser(user);
    if (!ref.mounted) {
      return;
    }

    state = state.copyWith(user: user);
  }

  Future<void> clearSession() async {
    await _store.clearSession();
    if (!ref.mounted) {
      return;
    }

    state = const AdminAuthSessionState();
  }
}
