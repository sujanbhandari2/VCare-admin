import 'package:vcare_admin/features/auth/domain/entities/auth_session.dart';

/// Result of `POST /auth/login` — either a full session or a 2FA challenge.
sealed class AuthLoginOutcome {
  const AuthLoginOutcome();
}

class AuthLoginSessionOutcome extends AuthLoginOutcome {
  const AuthLoginSessionOutcome(this.session);

  final AuthSession session;
}

class AuthLoginTwoFactorChallenge extends AuthLoginOutcome {
  const AuthLoginTwoFactorChallenge({
    required this.challengeToken,
    required this.expiresIn,
  });

  final String challengeToken;
  final int expiresIn;
}
