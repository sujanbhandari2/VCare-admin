import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';

enum AdminLoginPhase { credentials, tenantSelection, twoFactor }

class AdminLoginState {
  const AdminLoginState({
    this.phase = AdminLoginPhase.credentials,
    this.tenantOptions = const [],
    this.storedEmail,
    this.storedPassword,
    this.challengeToken,
    this.expiresIn,
    this.errorMessage,
    this.isSubmitting = false,
    this.isResending = false,
  });

  final AdminLoginPhase phase;
  final List<TenantOption> tenantOptions;
  final String? storedEmail;
  final String? storedPassword;
  final String? challengeToken;
  final int? expiresIn;
  final String? errorMessage;
  final bool isSubmitting;
  final bool isResending;

  AdminLoginState copyWith({
    AdminLoginPhase? phase,
    List<TenantOption>? tenantOptions,
    String? storedEmail,
    String? storedPassword,
    String? challengeToken,
    int? expiresIn,
    String? errorMessage,
    bool? isSubmitting,
    bool? isResending,
    bool clearError = false,
    bool clearCredentials = false,
    bool clearChallenge = false,
  }) {
    return AdminLoginState(
      phase: phase ?? this.phase,
      tenantOptions: tenantOptions ?? this.tenantOptions,
      storedEmail: clearCredentials ? null : storedEmail ?? this.storedEmail,
      storedPassword:
          clearCredentials ? null : storedPassword ?? this.storedPassword,
      challengeToken:
          clearChallenge ? null : challengeToken ?? this.challengeToken,
      expiresIn: clearChallenge ? null : expiresIn ?? this.expiresIn,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isResending: isResending ?? this.isResending,
    );
  }
}
