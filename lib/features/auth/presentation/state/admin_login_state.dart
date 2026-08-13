import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';

enum AdminLoginPhase { credentials, tenantSelection }

class AdminLoginState {
  const AdminLoginState({
    this.phase = AdminLoginPhase.credentials,
    this.tenantOptions = const [],
    this.storedEmail,
    this.storedPassword,
    this.errorMessage,
    this.isSubmitting = false,
  });

  final AdminLoginPhase phase;
  final List<TenantOption> tenantOptions;
  final String? storedEmail;
  final String? storedPassword;
  final String? errorMessage;
  final bool isSubmitting;

  AdminLoginState copyWith({
    AdminLoginPhase? phase,
    List<TenantOption>? tenantOptions,
    String? storedEmail,
    String? storedPassword,
    String? errorMessage,
    bool? isSubmitting,
    bool clearError = false,
    bool clearCredentials = false,
  }) {
    return AdminLoginState(
      phase: phase ?? this.phase,
      tenantOptions: tenantOptions ?? this.tenantOptions,
      storedEmail: clearCredentials ? null : storedEmail ?? this.storedEmail,
      storedPassword:
          clearCredentials ? null : storedPassword ?? this.storedPassword,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
