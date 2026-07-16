import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';

class AuthSetupAccountResult {
  const AuthSetupAccountResult({
    required this.session,
    this.profileId,
    this.menu = const [],
  });

  final AuthSession session;
  final String? profileId;
  final List<String> menu;
}
