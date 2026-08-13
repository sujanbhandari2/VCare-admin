import 'dart:convert';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';

/// Sync Hive cache for tenant branding — flash-free first paint.
class TenantBrandingSessionStore {
  const TenantBrandingSessionStore(this.storage);

  final StorageService storage;

  String? readActiveSlug() {
    final value = storage.get(StorageKeys.tenantBrandingActiveSlug);
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;

    final authSlug = storage.get(StorageKeys.authTenantSlug)?.toString().trim();
    return (authSlug == null || authSlug.isEmpty) ? null : authSlug;
  }

  TenantBranding? readForSlug(String slug) {
    final raw = storage.get(StorageKeys.tenantBranding(slug));
    if (raw is! String || raw.trim().isEmpty) return null;

    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final branding = TenantBranding.fromJson(Map<String, dynamic>.from(map));
      final fontKey =
          storage.get(StorageKeys.tenantFontTheme(slug))?.toString().trim();
      if (fontKey != null && fontKey.isNotEmpty) {
        return branding.copyWith(fontThemeKey: fontKey);
      }
      return branding;
    } catch (_) {
      return null;
    }
  }

  TenantBranding readActiveOrDefaults({String? fallbackSlug}) {
    final slug = readActiveSlug() ?? fallbackSlug;
    if (slug == null || slug.isEmpty) {
      return TenantBranding.defaults;
    }
    return readForSlug(slug) ?? TenantBranding.defaults;
  }

  Future<void> save({
    required String slug,
    required TenantBranding branding,
    bool setActive = true,
  }) async {
    await storage.set(
      StorageKeys.tenantBranding(slug),
      jsonEncode(branding.toJson()),
    );
    await storage.set(
      StorageKeys.tenantFontTheme(slug),
      branding.fontThemeKey,
    );
    if (setActive) {
      await storage.set(StorageKeys.tenantBrandingActiveSlug, slug);
    }
  }

  Future<void> setActiveSlug(String? slug) async {
    if (slug == null || slug.trim().isEmpty) {
      await storage.remove(StorageKeys.tenantBrandingActiveSlug);
      return;
    }
    await storage.set(StorageKeys.tenantBrandingActiveSlug, slug.trim());
  }
}
