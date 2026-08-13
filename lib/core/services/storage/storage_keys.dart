class StorageKeys {
  static const String loggedInUserToken = 'token';
  static const String loggedInUserRefreshToken = 'refresh-token';
  static const String loggedInUserId = 'logged_in_user_id';
  static const String loggedInUserUuid = 'logged_in_user_uuid';
  static const String loggedInUserProfileId = 'logged_in_user_profile_id';
  static const String loggedInUserTenantId = 'logged_in_user_tenant_id';
  static const String loggedInUserEmail = 'logged_in_user_email';
  static const String loggedInUserUsername = 'logged_in_user_username';

  /// Admin auth session (mirrors web vcare-auth-store).
  static const String authUser = 'auth_user';
  static const String authMenu = 'auth_menu';
  static const String authUrls = 'auth_urls';
  static const String authTenantSlug = 'auth_tenant_slug';

  /// Tenant branding cache (keyed by slug; survives logout for no-flash paint).
  static const String tenantBrandingActiveSlug = 'vcare.branding.active_slug';
  static String tenantBranding(String slug) => 'vcare.branding.$slug';
  static String tenantFontTheme(String slug) => 'vcare.fontTheme.$slug';

  /// Stable install device id for 2FA remember-device (survives logout).
  static const String deviceId = 'vcare.device-id';
  static const String locale = 'language_locale';
  static const String themeSeedColor = 'theme_seed_color';
  static const String themeMode = 'theme_mode';
  static const String textScale = 'text_scale';
  static const String colorSchemeStyle = 'color_scheme_style';
  static const String contrastMode = 'contrast_mode';
  static const String themeSeedSourceImagePath = 'theme_seed_source_image_path';
  static const String themeSeedUseImageSource = 'theme_seed_use_image_source';
  static const String alreadyOnboarded = 'onboarding_already_done';
  static const String hasLocationPermission = 'has_location_permission';
  static const String roadGeoJsonFilePath = 'road_geoJson_file_path';
  static const String houseGeoJsonFilePath = 'house_geoJson_file_path';
  static const String lastUpdateDate = 'last_update_date';
  static const String storeBaseLayer = 'store_base_layer';
  static const String storeBaseLayerId = 'store_base_layer_id';
  static const String savedOfflineDownload = 'saved_offline_download';

  static const String tokenRefreshedDate = 'token_refreshed_date';
  static const String lastSyncedFcmToken = 'last_synced_fcm_token';
  static const String lastSyncedFcmUserId = 'last_synced_fcm_user_id';
  static const String localProfile = 'vcare.profile.v2';
  static const String findCareSearchLocation = 'vcare.search-location.v3';
  static const String findCareMockProviderFavorites = 'vcare:favorites:providers';
}
