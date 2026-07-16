import 'package:vcare_admin/core/config/env/env.dart';
import 'package:vcare_admin/core/config/env/env_keys.dart';

/// Reads health messenger configuration from the bundled `.env` file.
class HealthMessengerEnv {
  HealthMessengerEnv._();

  static String _env(String primaryKey, String fallbackKey) {
    final primary = Env.instance.valueOf(primaryKey)?.trim() ?? '';
    if (primary.isNotEmpty) {
      return primary;
    }
    return Env.instance.valueOf(fallbackKey)?.trim() ?? '';
  }

  static String get apiBaseUrl =>
      _env(EnvKeys.healthMessengerApiBaseUrl, EnvKeys.viteApiUrl);

  static String get socketUrl =>
      _env(EnvKeys.healthMessengerSocketUrl, EnvKeys.viteSocketUrl);

  static String get apiKey =>
      _env(EnvKeys.healthMessengerApiKey, EnvKeys.viteWidgetAccessKey);

  static String get externalTenantId =>
      Env.instance.valueOf(EnvKeys.healthMessengerExternalTenantId)?.trim() ??
      '';

  static String get runtimeEnv =>
      (Env.instance.valueOf('ENV') ?? '').trim().toLowerCase();
}
