import 'package:flutter_template/core/config/env/env.dart';
import 'package:flutter_template/core/config/env/env_keys.dart';
import 'package:flutter_template/core/config/flavor/configuration.dart';
import 'package:flutter_template/core/config/flavor/flavor.dart';

class ProductionConfiguration extends Configuration {
  /// Private internal constructor
  ///
  ProductionConfiguration._internal()
    : super(
        maxCacheAge: const Duration(days: 45),
        dioCacheForceRefreshKey: 'dio_cache_force_refresh_key',
    hiveBoxName: Env.instance.valueOf(EnvKeys.storageBoxName) ?? '',
    baseUrl: Env.instance.valueOf(EnvKeys.baseUrl) ?? '',
      );

  /// Singleton instance of this class
  ///
  static final ProductionConfiguration instance = ._internal();

  @override
  Flavor get flavor => .production;

  @override
  String get apiBaseUrl => apiBaseUrlV1;
}
