import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';

abstract class BiometricCredentialLocalStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class SecureBiometricCredentialLocalStore
    implements BiometricCredentialLocalStore {
  SecureBiometricCredentialLocalStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> read() {
    return _secureStorage.read(key: StorageKeys.biometricCredential);
  }

  @override
  Future<void> write(String value) {
    return _secureStorage.write(
      key: StorageKeys.biometricCredential,
      value: value,
    );
  }

  @override
  Future<void> delete() {
    return _secureStorage.delete(key: StorageKeys.biometricCredential);
  }
}

class InMemoryBiometricCredentialLocalStore
    implements BiometricCredentialLocalStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    _value = value;
  }

  @override
  Future<void> delete() async {
    _value = null;
  }
}
