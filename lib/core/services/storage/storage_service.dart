/// Storage service interface
abstract class StorageService {
  /// Method to initialize storage service
  ///
  Future<void> init(String name);

  /// Removes item from storage by a key
  ///
  Future<void> remove(String key);

  /// Retrieves item from storage by a key
  ///
  dynamic get(
    String key, {
    dynamic defaultValue,
  });

  /// Clears storage
  ///
  Future<void> clear();

  /// Checks if an item exists in storage by a key
  ///
  bool has(String key);

  /// Sets an item data in storage by a key
  ///
  Future<void> set(String key, dynamic data);

  /// Terminates service
  ///
  Future<void> close();
}
