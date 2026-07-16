import 'package:health_messenger_ui/lib/health_messenger_client.dart';
import 'package:vcare_admin/core/config/env/health_messenger_env.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/messages/health_messenger/mappers/auth_identity_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/user_profile.dart';

/// Immutable bootstrap parameters for [ChatSession.bootstrap].
class HealthMessengerBootstrapConfig {
  const HealthMessengerBootstrapConfig({
    required this.apiBaseUrl,
    required this.socketUrl,
    required this.apiKey,
    required this.externalTenantId,
    required this.externalUserId,
    required this.externalUserRole,
    required this.email,
    required this.displayName,
    this.profile,
  });

  final String apiBaseUrl;
  final String socketUrl;
  final String apiKey;
  final String externalTenantId;
  final String externalUserId;
  final String externalUserRole;
  final String email;
  final String displayName;
  final String? profile;

  static const Set<String> _knownExternalTenantIdPrefixes = {
    'DEV_',
    'QA_',
    'UAT_',
    'PROD_',
  };

  /// Default role until VCare exposes tenant roles on the profile API.
  static const String defaultExternalUserRole = 'AGENT';

  static String flavorExternalTenantIdPrefix() {
    final compileTimeFlavor = const String.fromEnvironment(
      'FLAVOR',
    ).trim().toLowerCase();
    final runtimeEnv = HealthMessengerEnv.runtimeEnv;

    final resolvedFlavor = compileTimeFlavor.isNotEmpty
        ? compileTimeFlavor
        : runtimeEnv;

    switch (resolvedFlavor) {
      case 'dev':
        return 'DEV_';
      case 'qa':
        return 'QA_';
      case 'uat':
        return 'UAT_';
      case 'prod':
        return 'PROD_';
      default:
        return '';
    }
  }

  static String prefixedExternalTenantId(String rawTenantId) {
    final id = rawTenantId.trim();
    if (id.isEmpty) {
      return '';
    }

    final upper = id.toUpperCase();
    for (final prefix in _knownExternalTenantIdPrefixes) {
      if (upper.startsWith(prefix)) {
        return id;
      }
    }

    final flavorPrefix = flavorExternalTenantIdPrefix();
    if (flavorPrefix.isEmpty) {
      return id;
    }

    return '$flavorPrefix$id';
  }

  static HealthMessengerBootstrapConfig? tryBuild({
    required StorageService storage,
    UserProfile? profile,
    String externalUserRole = defaultExternalUserRole,
  }) {
    final identity = AuthIdentityMapper(storage: storage, profile: profile);
    final apiBaseUrl = HealthMessengerEnv.apiBaseUrl;
    final socketUrl = HealthMessengerEnv.socketUrl;
    final apiKey = HealthMessengerEnv.apiKey;
    final externalTenantId =
        prefixedExternalTenantId(HealthMessengerEnv.externalTenantId);
    final externalUserId = identity.externalUserId;
    final email = identity.email;
    final displayName = identity.displayName;
    final profilePicture = identity.profilePicture;

    if (apiBaseUrl.isEmpty ||
        socketUrl.isEmpty ||
        apiKey.isEmpty ||
        externalTenantId.isEmpty ||
        externalUserId.isEmpty ||
        email.isEmpty) {
      return null;
    }

    return HealthMessengerBootstrapConfig(
      apiBaseUrl: apiBaseUrl,
      socketUrl: socketUrl,
      apiKey: apiKey,
      externalTenantId: externalTenantId,
      externalUserId: externalUserId,
      externalUserRole: externalUserRole.trim().isEmpty
          ? kChatUserDefaultExternalRole.toUpperCase()
          : externalUserRole.trim().toUpperCase(),
      email: email,
      displayName: displayName,
      profile: profilePicture,
    );
  }

  static String describeValidationFailure({
    required StorageService storage,
    UserProfile? profile,
  }) {
    if (HealthMessengerEnv.apiBaseUrl.isEmpty) {
      return 'Missing VITE_API_URL or HEALTH_MESSENGER_API_BASE_URL in environment.';
    }
    if (HealthMessengerEnv.socketUrl.isEmpty) {
      return 'Missing VITE_SOCKET_URL or HEALTH_MESSENGER_SOCKET_URL in environment.';
    }
    if (HealthMessengerEnv.apiKey.isEmpty) {
      return 'Missing VITE_WIDGET_ACCESS_KEY or HEALTH_MESSENGER_API_KEY in environment.';
    }
    if (HealthMessengerEnv.externalTenantId.isEmpty) {
      return 'Missing HEALTH_MESSENGER_EXTERNAL_TENANT_ID in environment.';
    }

    final identity = AuthIdentityMapper(storage: storage, profile: profile);
    if (identity.externalUserId.isEmpty) {
      return 'User ID is missing from the signed-in session.';
    }
    if (identity.email.isEmpty) {
      return 'Email is missing from the signed-in session.';
    }

    return 'Chat configuration is incomplete.';
  }
}
