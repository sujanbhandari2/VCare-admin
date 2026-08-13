class AdminLoginPayloadBuilder {
  const AdminLoginPayloadBuilder({required this.defaultTenantSlug});

  final String defaultTenantSlug;

  Map<String, dynamic> build({
    required String email,
    required String password,
    String? tenantSlug,
  }) {
    final resolvedTenantSlug = tenantSlug?.trim().isNotEmpty == true
        ? tenantSlug!.trim()
        : defaultTenantSlug.trim();

    return {
      'identifier': email.trim(),
      'password': password,
      if (resolvedTenantSlug.isNotEmpty) 'tenantSlug': resolvedTenantSlug,
    };
  }
}
