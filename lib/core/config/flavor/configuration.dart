import 'package:vcare_admin/core/config/env/env.dart';
import 'package:vcare_admin/core/config/env/env_keys.dart';
import 'package:vcare_admin/core/config/flavor/configuration/development_configuration.dart';
import 'package:vcare_admin/core/config/flavor/configuration/production_configuration.dart';
import 'package:vcare_admin/core/config/flavor/configuration/qa_configuration.dart';
import 'package:vcare_admin/core/config/flavor/configuration/uat_configuration.dart';

import 'package:vcare_admin/core/config/flavor/flavor.dart';

abstract class Configuration {
  /// The max allowed age duration for the http cache
  final Duration maxCacheAge;

  /// Key used in dio options to indicate whether
  /// cache should be force refreshed
  final String dioCacheForceRefreshKey;

  /// HIVE's box name
  final String hiveBoxName;

  /// Base Url
  ///
  final String baseUrl;

  /// Api Versions
  final String apiV1 = 'api/v1/';
  final String apiV2 = 'api/v2/';
  final String apiV3 = 'api/v3/';

  /// Getters for api base url
  ///
  String get apiBaseUrlV1 => "$baseUrl$apiV1";

  String get apiBaseUrlV2 => "$baseUrl$apiV2";

  String get apiBaseUrlV3 => "$baseUrl$apiV3";

  String get apiBaseUrl;

  /// Default tenant slug for admin login (web: VITE_DEFAULT_TENANT_SLUG).
  String get defaultTenantSlug {
    final slug =
        Env.instance.valueOf(EnvKeys.defaultTenantSlug)?.trim() ?? '';
    return slug.isEmpty ? 'vcare-advocacy' : slug;
  }

  /// Getter for flavor
  ///
  Flavor get flavor;

  /// Constructor
  ///
  const Configuration({
    required this.maxCacheAge,
    required this.dioCacheForceRefreshKey,
    required this.hiveBoxName,
    required this.baseUrl,
  });

  /// Method to get configuration for different flavour
  ///
  static Configuration of([Flavor? flavor]) {
    flavor ??= Flavor.fromEnvironment;

    return switch (flavor) {
      Flavor.dev => DevelopmentConfiguration.instance,
      Flavor.qa => QaConfiguration.instance,
      Flavor.uat => UatConfiguration.instance,
      Flavor.prod => ProductionConfiguration.instance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Configuration &&
          runtimeType == other.runtimeType &&
          maxCacheAge == other.maxCacheAge &&
          dioCacheForceRefreshKey == other.dioCacheForceRefreshKey &&
          hiveBoxName == other.hiveBoxName &&
          baseUrl == other.baseUrl;

  @override
  int get hashCode =>
      maxCacheAge.hashCode ^
      dioCacheForceRefreshKey.hashCode ^
      hiveBoxName.hashCode ^
      baseUrl.hashCode;
}
