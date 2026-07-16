import 'dart:convert';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/profile/data/models/local_profile_model.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/repositories/local_profile_repository.dart';

class LocalProfileRepositoryImpl implements LocalProfileRepository {
  LocalProfileRepositoryImpl(this._storage);

  final StorageService _storage;

  static const LocalProfile defaults = LocalProfile(
    fullName: '',
    email: '',
    phone: '',
    dob: '',
  );

  @override
  LocalProfile load() {
    final raw = _storage.get(StorageKeys.localProfile);
    if (raw is! String || raw.isEmpty) {
      return defaults;
    }

    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return defaults;
      }
      return LocalProfileModel.fromJson(
        Map<String, dynamic>.from(json),
      ).toEntity();
    } catch (_) {
      return defaults;
    }
  }

  @override
  Future<void> save(LocalProfile profile) async {
    final encoded = jsonEncode(LocalProfileModel.fromEntity(profile).toJson());
    await _storage.set(StorageKeys.localProfile, encoded);
  }
}
