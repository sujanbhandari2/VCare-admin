import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_login_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';
import '../../../../fixtures/repository_fixtures.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('AdminLoginStateNotifier', () {
    late FakeAuthRepository repository;
    late InMemoryStorageService storageService;

    setUp(() {
      repository = FakeAuthRepository();
      storageService = InMemoryStorageService();
    });

    test('persists session on successful login', () async {
      repository.adminLoginResult = Success(
        AdminLoginAuthenticated(RepositoryFixtures.adminAuthSession()),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
          storageServiceProvider.overrideWithValue(storageService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(adminLoginStateProvider.notifier).submitCredentials(
        email: 'admin@example.com',
        password: 'Password1!',
      );

      final session = container.read(adminAuthSessionProvider);
      expect(session.isAuthenticated, isTrue);
      expect(session.user?.email, 'admin@example.com');
      expect(repository.lastAdminLoginEmail, 'admin@example.com');
    });
  });
}
