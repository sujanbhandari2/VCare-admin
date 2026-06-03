import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_template/core/services/storage/storage_keys.dart';
import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_template/features/notifications/presentation/providers/notification_repository_provider.dart';

import '../../../../fixtures/repositories/fake_notification_repository.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('FcmDeviceCheckRequestStateNotifier', () {
    late InMemoryStorageService storageService;
    late FakeNotificationRepository repository;
    late ProviderContainer container;

    setUp(() async {
      storageService = InMemoryStorageService();
      await storageService.set(StorageKeys.loggedInUserId, 21);

      repository = FakeNotificationRepository();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          notificationRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });
  });
}
