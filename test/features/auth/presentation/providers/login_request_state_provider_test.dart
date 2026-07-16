import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/enums/login_request_type.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/login_request_state_provider.dart';

import '../../../../helpers/in_memory_storage_service.dart';
import '../../../../fixtures/repositories/fake_auth_repository.dart';
import '../../../../fixtures/repository_fixtures.dart';

void main() {
  group('LoginRequestStateNotifier', () {
    late InMemoryStorageService storageService;
    late FakeAuthRepository repository;
    late ProviderContainer container;

    setUp(() {
      storageService = InMemoryStorageService();
      repository = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService),
          authRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('login success stores session and updates state', () async {
      repository.loginResult = Success(
        RepositoryFixtures.authSession(
          profileId: 'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
        ),
      );

      await container
          .read(loginRequestStateProvider.notifier)
          .login(
            payloads: const {
              'identifier': 'fixture@example.com',
              'password': 'pw',
            },
            type: LoginRequestType.password,
          );

      final state = container.read(loginRequestStateProvider);

      expect(state.requesting, isFalse);
      expect(state.response?.access, isNotEmpty);
      expect(state.error, isNull);
      expect(
        storageService.get(StorageKeys.loggedInUserToken),
        state.response?.access,
      );
      expect(
        storageService.get(StorageKeys.loggedInUserProfileId),
        'd06cf672-9e6c-4bcc-bb37-ccf13ff35c4a',
      );
      expect(repository.lastLoginPayloads?['identifier'], 'fixture@example.com');
    });
  });
}
