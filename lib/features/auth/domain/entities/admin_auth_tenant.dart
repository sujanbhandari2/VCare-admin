class AdminAuthTenant {
  const AdminAuthTenant({
    required this.id,
    required this.slug,
    required this.name,
  });

  final String id;
  final String slug;
  final String name;
}

class TenantOption {
  const TenantOption({
    required this.slug,
    required this.name,
  });

  final String slug;
  final String name;
}
