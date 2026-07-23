import 'package:vcare_admin/features/auth/data/models/login_response_model.dart';

class AuthSetupAccountResultModel {
  AuthSetupAccountResultModel({
    required this.session,
    this.profileId,
    this.tenantId,
    this.menu = const [],
  });

  final LoginResponseModel session;
  final String? profileId;
  final String? tenantId;
  final List<String> menu;

  factory AuthSetupAccountResultModel.fromJson(Map<String, dynamic> json) {
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

    return AuthSetupAccountResultModel(
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
}
