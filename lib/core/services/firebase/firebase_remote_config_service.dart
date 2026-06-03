import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../../shared/utils/logger.dart';

class FirebaseRemoteConfigService {
  /// Remote Config Instance
  ///
  final FirebaseRemoteConfig _remoteConfig;

  /// Private internal constructor
  ///
  FirebaseRemoteConfigService._()
    : _remoteConfig = FirebaseRemoteConfig.instance;

  /// Private instance of FirebaseRemoteConfigService
  ///
  static FirebaseRemoteConfigService? _instance;

  /// Lazy-loaded singleton instance of this class
  ///
  static FirebaseRemoteConfigService get instance {
    if (_instance == null) {
      Logger.logMessage("FirebaseRemoteConfigService is initialized!");
    }
    _instance ??= FirebaseRemoteConfigService._();
    return _instance!;
  }

  /// Initializing the remote config
  ///
  Future<void> init({
    Duration minimumFetchInterval = const Duration(minutes: 10),
    Duration fetchTimeout = const Duration(minutes: 1),
  }) async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: minimumFetchInterval,
      ),
    );

    await _remoteConfig.fetchAndActivate();
  }

  Future<bool> refetch() async {
    try {
      await _remoteConfig.ensureInitialized();
      return await _remoteConfig.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  Future<T?> get<T>(String key) async {
    try {
      await _remoteConfig.ensureInitialized();

      final value = switch (T) {
        const (bool) => _remoteConfig.getBool(key),
        const (double) => _remoteConfig.getDouble(key),
        const (int) => _remoteConfig.getInt(key),
        const (String) => _remoteConfig.getString(key),
        _ => null,
      };

      return value as T?;
    } catch (_) {
      return null;
    }
  }

  Future<T?> getOrDefault<T>(String key, {T? defaultValue}) async {
    return await get(key) ?? defaultValue;
  }

  Stream<RemoteConfigUpdate> get onConfigUpdated =>
      _remoteConfig.onConfigUpdated;
}
