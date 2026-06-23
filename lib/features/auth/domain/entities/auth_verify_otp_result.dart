import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';

class AuthVerifyOtpResult {
  const AuthVerifyOtpResult({this.session});

  final AuthSession? session;
}
