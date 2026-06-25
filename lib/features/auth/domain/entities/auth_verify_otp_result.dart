import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';

class AuthVerifyOtpResult {
  const AuthVerifyOtpResult({this.session, this.registrationToken});

  final AuthSession? session;
  final String? registrationToken;
}
