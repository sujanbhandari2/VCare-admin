import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/home/data/repositories/referral_repository_impl.dart';
import 'package:vcare_admin/features/home/domain/repositories/referral_repository.dart';

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepositoryImpl(ref.watch(storageServiceProvider));
});
