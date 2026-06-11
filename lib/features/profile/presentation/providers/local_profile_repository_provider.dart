import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/profile/data/repositories/local_profile_repository_impl.dart';
import 'package:vcare_admin/features/profile/domain/repositories/local_profile_repository.dart';

part 'local_profile_repository_provider.g.dart';

@Riverpod(keepAlive: true)
LocalProfileRepository localProfileRepository(Ref ref) {
  return LocalProfileRepositoryImpl(ref.read(storageServiceProvider));
}
