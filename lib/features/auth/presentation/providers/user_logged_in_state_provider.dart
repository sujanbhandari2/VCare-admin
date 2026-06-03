import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';

part 'user_logged_in_state_provider.g.dart';

@riverpod
bool userLoggedInState(Ref ref) {
  final storageService = ref.read(storageServiceProvider);

  final token = storageService.get(
    StorageKeys.loggedInUserToken,
    defaultValue: '',
  );

  final userId = storageService.get(StorageKeys.loggedInUserId);

  return token is String &&
      token.trim().isNotEmpty &&
      userId is int &&
      userId > 0;
}
