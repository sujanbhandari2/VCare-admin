import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/config/flavor/configuration_provider.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/core/styles/vcare_hsl.dart';
import 'package:vcare_admin/features/tenant_branding/domain/entities/tenant_branding.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/providers/tenant_branding_repository_provider.dart';
import 'package:vcare_admin/features/tenant_branding/presentation/state/tenant_branding_state.dart';

part 'tenant_branding_state_provider.g.dart';

@Riverpod(keepAlive: true)
class TenantBrandingStateNotifier extends _$TenantBrandingStateNotifier {
  @override
  TenantBrandingState build() {
    final store = ref.read(tenantBrandingSessionStoreProvider);
    final fallbackSlug =
        ref.read(flavorConfigurationProvider).defaultTenantSlug;
    final slug = store.readActiveSlug() ?? fallbackSlug;
    final branding = store.readActiveOrDefaults(fallbackSlug: fallbackSlug);
    return TenantBrandingState(
      branding: branding,
      activeSlug: slug,
    );
  }

  String _resolveSlug(String? tenantSlug) {
    if (tenantSlug != null && tenantSlug.trim().isNotEmpty) {
      return tenantSlug.trim();
    }
    final storage = ref.read(storageServiceProvider);
    final authSlug =
        storage.get(StorageKeys.authTenantSlug)?.toString().trim() ?? '';
    if (authSlug.isNotEmpty) return authSlug;
    return ref.read(flavorConfigurationProvider).defaultTenantSlug;
  }

  Future<void> hydrateFromCache({String? tenantSlug}) async {
    final slug = _resolveSlug(tenantSlug);
    final store = ref.read(tenantBrandingSessionStoreProvider);
    final cached = store.readForSlug(slug) ?? TenantBranding.defaults;
    await store.setActiveSlug(slug);
    if (!ref.mounted) return;
    state = state.copyWith(branding: cached, activeSlug: slug);
  }

  Future<void> refreshFromApi({
    String? tenantSlug,
    bool forceRefresh = true,
    void Function(TenantBranding? data)? onCompleted,
  }) async {
    final slug = _resolveSlug(tenantSlug);
    if (ref.mounted) {
      state = state.loadingFetch().copyWith(activeSlug: slug);
    }

    final response = await ref
        .read(tenantBrandingRepositoryProvider)
        .fetchBranding(forceRefresh: forceRefresh);

    if (response.isFailure) {
      if (ref.mounted) {
        state = state.failureFetch(response.failureOrNull?.message);
      }
      onCompleted?.call(null);
      return;
    }

    final result = response.dataOrNull!;
    await ref.read(tenantBrandingSessionStoreProvider).save(
          slug: slug,
          branding: result,
        );
    if (ref.mounted) {
      state = state.successFetch(result, slug: slug);
    }
    onCompleted?.call(result);
  }

  Future<void> applyLocal(TenantBranding branding, {String? tenantSlug}) async {
    final slug = _resolveSlug(tenantSlug);
    await ref.read(tenantBrandingSessionStoreProvider).save(
          slug: slug,
          branding: branding,
        );
    if (!ref.mounted) return;
    state = state.copyWith(branding: branding, activeSlug: slug);
  }

  Future<void> updateBranding({
    String? logoUrl,
    String? iconUrl,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    bool clearLogo = false,
    bool clearIcon = false,
    void Function(TenantBranding? data)? onCompleted,
  }) async {
    final slug = _resolveSlug(null);
    final previous = state.branding;

    final optimistic = previous.copyWith(
      logoUrl: logoUrl,
      iconUrl: iconUrl,
      primaryColor: primaryColor != null
          ? VCareHsl.normalizeHex(primaryColor, fallback: previous.primaryColor)
          : null,
      secondaryColor: secondaryColor != null
          ? VCareHsl.normalizeHex(
              secondaryColor,
              fallback: previous.secondaryColor,
            )
          : null,
      accentColor: accentColor != null
          ? VCareHsl.normalizeHex(accentColor, fallback: previous.accentColor)
          : null,
      clearLogo: clearLogo,
      clearIcon: clearIcon,
    );

    if (ref.mounted) {
      state = state.loadingUpdate().copyWith(branding: optimistic);
    }

    final response = await ref
        .read(tenantBrandingRepositoryProvider)
        .updateBranding(
          logoUrl: logoUrl,
          iconUrl: iconUrl,
          primaryColor: primaryColor != null
              ? VCareHsl.normalizeHex(
                  primaryColor,
                  fallback: previous.primaryColor,
                )
              : null,
          secondaryColor: secondaryColor != null
              ? VCareHsl.normalizeHex(
                  secondaryColor,
                  fallback: previous.secondaryColor,
                )
              : null,
          accentColor: accentColor != null
              ? VCareHsl.normalizeHex(
                  accentColor,
                  fallback: previous.accentColor,
                )
              : null,
          clearLogo: clearLogo,
          clearIcon: clearIcon,
        );

    if (response.isFailure) {
      if (ref.mounted) {
        state = state
            .failureUpdate(response.failureOrNull?.message)
            .copyWith(branding: previous);
      }
      onCompleted?.call(null);
      return;
    }

    final result = response.dataOrNull!;
    final merged = result.copyWith(
      fontThemeKey: result.fontThemeKey.isEmpty
          ? previous.fontThemeKey
          : result.fontThemeKey,
    );
    await ref.read(tenantBrandingSessionStoreProvider).save(
          slug: slug,
          branding: merged,
        );
    if (ref.mounted) {
      state = state.successUpdate(merged, slug: slug);
    }
    onCompleted?.call(merged);
  }

  Future<void> updateFontTheme({
    required String fontThemeKey,
    void Function(TenantBranding? data)? onCompleted,
  }) async {
    final slug = _resolveSlug(null);
    final previous = state.branding;
    final optimistic = previous.copyWith(fontThemeKey: fontThemeKey);

    if (ref.mounted) {
      state = state.loadingUpdate().copyWith(branding: optimistic);
    }

    final response = await ref
        .read(tenantBrandingRepositoryProvider)
        .updateFontTheme(fontThemeKey: fontThemeKey);

    if (response.isFailure) {
      if (ref.mounted) {
        state = state
            .failureUpdate(response.failureOrNull?.message)
            .copyWith(branding: previous);
      }
      onCompleted?.call(null);
      return;
    }

    final result = response.dataOrNull!;
    final merged = result.copyWith(
      fontThemeKey: fontThemeKey,
      logoUrl: result.logoUrl ?? previous.logoUrl,
      iconUrl: result.iconUrl ?? previous.iconUrl,
    );
    await ref.read(tenantBrandingSessionStoreProvider).save(
          slug: slug,
          branding: merged,
        );
    if (ref.mounted) {
      state = state.successUpdate(merged, slug: slug);
    }
    onCompleted?.call(merged);
  }

  Future<void> resetToDefaults({
    void Function(TenantBranding? data)? onCompleted,
  }) async {
    TenantBranding? brandingResult;
    await updateBranding(
      logoUrl: null,
      iconUrl: null,
      primaryColor: TenantBranding.defaults.primaryColor,
      secondaryColor: TenantBranding.defaults.secondaryColor,
      accentColor: TenantBranding.defaults.accentColor,
      clearLogo: true,
      clearIcon: true,
      onCompleted: (data) => brandingResult = data,
    );
    if (brandingResult == null) {
      onCompleted?.call(null);
      return;
    }
    await updateFontTheme(
      fontThemeKey: TenantBranding.defaults.fontThemeKey,
      onCompleted: onCompleted,
    );
  }

  /// On logout: keep slug-keyed cache, reset active branding to default tenant.
  Future<void> resetActiveToDefaultTenant() async {
    final fallbackSlug =
        ref.read(flavorConfigurationProvider).defaultTenantSlug;
    final store = ref.read(tenantBrandingSessionStoreProvider);
    final cached = store.readForSlug(fallbackSlug) ?? TenantBranding.defaults;
    await store.setActiveSlug(fallbackSlug);
    if (!ref.mounted) return;
    state = TenantBrandingState(branding: cached, activeSlug: fallbackSlug);
  }
}
