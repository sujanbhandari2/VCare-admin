import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';

part 'user_logged_in_state_provider.g.dart';

@riverpod
bool userLoggedInState(Ref ref) {
  final storageService = ref.read(storageServiceProvider);

  final token = storageService.get(
    StorageKeys.loggedInUserToken,
    defaultValue: '',
  );

  final userId = storageService.get(StorageKeys.loggedInUserId);
  final profileId = storageService.get(StorageKeys.loggedInUserProfileId);

  final hasValidUserId = userId is int && userId > 0;
  final hasValidProfileId =
      profileId is String && profileId.trim().isNotEmpty;

  return token is String &&
      token.trim().isNotEmpty &&
      (hasValidUserId || hasValidProfileId);
}
