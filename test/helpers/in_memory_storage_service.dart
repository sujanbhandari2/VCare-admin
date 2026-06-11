import 'package:vcare_admin/core/services/storage/storage_service.dart';

class InMemoryStorageService implements StorageService {
  final Map<String, dynamic> _store = <String, dynamic>{};

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<void> close() async {}

  @override
  dynamic get(String key, {dynamic defaultValue}) =>
      _store.containsKey(key) ? _store[key] : defaultValue;

  @override
  bool has(String key) => _store.containsKey(key);

  @override
  Future<void> init(String name) async {}

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> set(String key, dynamic data) async {
    _store[key] = data;
  }
}
