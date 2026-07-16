import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';

part 'logged_in_user_id_provider.g.dart';

@Riverpod(keepAlive: true)
int? loggedInUserId(Ref ref) {
  final storageService = ref.read(storageServiceProvider);

  final userId = storageService.get(StorageKeys.loggedInUserId);

  return userId is int ? userId : null;
}
