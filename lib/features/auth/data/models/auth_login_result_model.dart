import 'package:vcare_admin/features/auth/data/models/login_response_model.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';

/// Parses login / verify-2fa payloads that may be a session or a 2FA challenge.
class AuthLoginResultModel {
  AuthLoginResultModel._({
    this.session,
    this.profileId,
    this.tenantId,
    this.menu = const [],
    this.requiresTwoFactor = false,
    this.challengeToken,
    this.expiresIn,
  });

  final LoginResponseModel? session;
  final String? profileId;
  final String? tenantId;
  final List<String> menu;
  final bool requiresTwoFactor;
  final String? challengeToken;
  final int? expiresIn;

  factory AuthLoginResultModel.fromJson(Map<String, dynamic> json) {
    final requiresTwoFactor = json['requiresTwoFactor'] == true;
    final challengeToken = (json['challengeToken'] as String?)?.trim();

    if (requiresTwoFactor &&
        challengeToken != null &&
        challengeToken.isNotEmpty) {
      final expiresRaw = json['expiresIn'];
      final expiresIn = expiresRaw is int
          ? expiresRaw
          : int.tryParse(expiresRaw?.toString() ?? '') ?? 0;
      return AuthLoginResultModel._(
        requiresTwoFactor: true,
        challengeToken: challengeToken,
        expiresIn: expiresIn,
      );
    }

    final user = json['user'] as Map<String, dynamic>? ?? {};
    final tokens = json['tokens'] as Map<String, dynamic>? ?? {};
    final menuRaw = json['menu'];
    final currentTenant = user['currentTenant'];
    final tenantId = currentTenant is Map<String, dynamic>
        ? currentTenant['id'] as String?
        : null;

    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final username = '$firstName $lastName'.trim();

    return AuthLoginResultModel._(
      session: LoginResponseModel(
        access: tokens['accessToken'] as String?,
        refresh: tokens['refreshToken'] as String?,
        email: user['email'] as String?,
        username: username.isEmpty ? null : username,
      ),
      profileId: user['id'] as String?,
      tenantId: tenantId,
      menu: menuRaw is List
          ? menuRaw.whereType<String>().toList()
          : const [],
    );
  }

  AuthLoginOutcome toOutcome() {
    if (requiresTwoFactor) {
      return AuthLoginTwoFactorChallenge(
        challengeToken: challengeToken ?? '',
        expiresIn: expiresIn ?? 0,
      );
    }

    final loginSession = session;
    return AuthLoginSessionOutcome(
      AuthSession(
        refresh: loginSession?.refresh,
        access: loginSession?.access,
        email: loginSession?.email,
        username: loginSession?.username,
        profileId: profileId,
        tenantId: tenantId,
      ),
    );
  }

  AuthSession toSession() {
    final outcome = toOutcome();
    if (outcome is AuthLoginSessionOutcome) {
      return outcome.session;
    }
    throw StateError('Login result is a 2FA challenge, not a session');
  }
}
