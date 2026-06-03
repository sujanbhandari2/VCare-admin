import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';

part 'is_already_onboarded_provider.g.dart';

@Riverpod(keepAlive: true)
bool isAlreadyOnboarded(Ref ref) {
  final storageService = ref.read(storageServiceProvider);

  final isAlreadyOnboarded = storageService.get(
    StorageKeys.alreadyOnboarded,
    defaultValue: false,
  );

  return isAlreadyOnboarded;
}
