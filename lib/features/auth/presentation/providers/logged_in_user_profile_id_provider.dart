import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';

part 'logged_in_user_profile_id_provider.g.dart';

@Riverpod(keepAlive: true)
int? loggedInUserProfileId(Ref ref) {
  final storageService = ref.read(storageServiceProvider);

  final profileId = storageService.get(StorageKeys.loggedInUserProfileId);

  return profileId is int ? profileId : null;
}
