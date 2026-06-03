import 'package:flutter_template/core/config/env/env_keys.dart';
import 'package:flutter_template/core/config/env/env.dart';
import 'package:flutter_template/core/config/flavor/configuration.dart';
import 'package:flutter_template/core/config/flavor/flavor.dart';

class DevelopmentConfiguration extends Configuration {
  /// Private internal constructor
  ///
  DevelopmentConfiguration._internal()
    : super(
        maxCacheAge: const Duration(days: 45),
        dioCacheForceRefreshKey: 'dio_cache_force_refresh_key_dev',
        hiveBoxName: Env.instance.valueOf(EnvKeys.storageBoxName) ?? '',
        baseUrl: Env.instance.valueOf(EnvKeys.baseUrl) ?? '',
      );

  /// Singleton instance of this class
  ///
  static final DevelopmentConfiguration instance = ._internal();

  @override
  Flavor get flavor => .dev;

  @override
  String get apiBaseUrl => baseUrl;
}
