import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service.dart';
import 'package:vcare_admin/features/home/domain/repositories/referral_repository.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  const ReferralRepositoryImpl(this._storage);

  final StorageService _storage;

  @override
  Future<String?> readSlug() async {
    final value = await _storage.get(StorageKeys.referralSlug);
    return value is String ? value : null;
  }

  @override
  Future<void> saveSlug(String slug) async {
    await _storage.set(StorageKeys.referralSlug, slug);
  }
}
