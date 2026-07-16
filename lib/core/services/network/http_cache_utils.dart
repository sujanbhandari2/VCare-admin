import 'package:vcare_admin/core/services/storage/storage_service.dart';

/// Removes all HTTP GET response cache entries from [storage].
///
/// Cache keys are prefixed with `GET:` (see [CacheInterceptor.createStorageKey]).
Future<void> clearHttpResponseCache(StorageService storage) async {
  final cacheKeys = storage.keys
      .where((key) => key.startsWith('GET:'))
      .toList(growable: false);

  for (final key in cacheKeys) {
    await storage.remove(key);
  }
}
