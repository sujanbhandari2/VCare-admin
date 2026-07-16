import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/notifications/domain/entities/fcm_device_check_response.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/fcm_device_check_request_state_provider.dart';
import 'package:vcare_admin/features/notifications/presentation/providers/notification_repository_provider.dart';

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

    test('checkFcmDeviceStatus updates state on success', () async {
      repository.checkResult = Success(
        FcmDeviceCheckResponse(
          hasFcmToken: true,
          fcmDeviceId: 7,
          fcmRegistrationToken: 'token',
        ),
      );

      await container
          .read(fcmDeviceCheckRequestStateProvider.notifier)
          .checkFcmDeviceStatus();

      final state = container.read(fcmDeviceCheckRequestStateProvider);
      expect(state.data?.hasFcmToken, isTrue);
      expect(state.data?.fcmDeviceId, 7);
      expect(repository.checkCallCount, 1);
    });

    test('checkFcmDeviceStatus updates state on failure', () async {
      repository.checkResult = Failure(
        HttpException(
          title: 'Error',
          message: 'Check failed',
          errorType: HttpErrorType.client,
        ),
      );

      await container
          .read(fcmDeviceCheckRequestStateProvider.notifier)
          .checkFcmDeviceStatus();

      final state = container.read(fcmDeviceCheckRequestStateProvider);
      expect(state.hasError, isTrue);
      expect(state.error, 'Check failed');
    });
  });
}
