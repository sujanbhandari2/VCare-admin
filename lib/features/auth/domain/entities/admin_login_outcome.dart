import 'admin_auth_session.dart';
import 'admin_auth_tenant.dart';

sealed class AdminLoginOutcome {
  const AdminLoginOutcome();
}

class AdminLoginAuthenticated extends AdminLoginOutcome {
  const AdminLoginAuthenticated(this.session);

  final AdminAuthSession session;
}

class AdminLoginTenantSelectionRequired extends AdminLoginOutcome {
  const AdminLoginTenantSelectionRequired(this.tenants);

  final List<TenantOption> tenants;
}

class AdminLoginTwoFactorRequired extends AdminLoginOutcome {
  const AdminLoginTwoFactorRequired({
    required this.challengeToken,
    required this.expiresIn,
  });

  final String challengeToken;
  final int expiresIn;
}

class AuthRefreshTokens {
  const AuthRefreshTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
