import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_login_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/admin_login_state.dart';

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

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
          storageServiceProvider.overrideWithValue(storageService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('persists session on successful login', () async {
      repository.adminLoginResult = Success(
        AdminLoginAuthenticated(RepositoryFixtures.adminAuthSession()),
      );

      final container = createContainer();

      await container.read(adminLoginStateProvider.notifier).submitCredentials(
            email: 'admin@example.com',
            password: 'Password1!',
          );

      final session = container.read(adminAuthSessionProvider);
      expect(session.isAuthenticated, isTrue);
      expect(session.user?.email, 'admin@example.com');
      expect(repository.lastAdminLoginEmail, 'admin@example.com');
    });

    test('moves to twoFactor phase when challenge is required', () async {
      repository.adminLoginResult = const Success(
        AdminLoginTwoFactorRequired(
          challengeToken: 'challenge-token',
          expiresIn: 600,
        ),
      );

      final container = createContainer();

      await container.read(adminLoginStateProvider.notifier).submitCredentials(
            email: 'admin@example.com',
            password: 'Password1!',
          );

      final state = container.read(adminLoginStateProvider);
      expect(state.phase, AdminLoginPhase.twoFactor);
      expect(state.challengeToken, 'challenge-token');
      expect(state.expiresIn, 600);
      expect(state.storedEmail, 'admin@example.com');
      expect(container.read(adminAuthSessionProvider).isAuthenticated, isFalse);
    });

    test('verifyTwoFactor persists session with rememberMe', () async {
      repository.adminLoginResult = const Success(
        AdminLoginTwoFactorRequired(
          challengeToken: 'challenge-token',
          expiresIn: 600,
        ),
      );
      repository.adminVerify2faResult = Success(
        RepositoryFixtures.adminAuthSession(),
      );

      final container = createContainer();
      final notifier = container.read(adminLoginStateProvider.notifier);

      await notifier.submitCredentials(
        email: 'admin@example.com',
        password: 'Password1!',
      );

      await notifier.verifyTwoFactor(
        otp: '123456',
        rememberMe: true,
      );

      expect(repository.lastAdminVerify2faChallengeToken, 'challenge-token');
      expect(repository.lastAdminVerify2faOtp, '123456');
      expect(repository.lastAdminVerify2faRememberMe, isTrue);

      final session = container.read(adminAuthSessionProvider);
      expect(session.isAuthenticated, isTrue);
      expect(container.read(adminLoginStateProvider).phase, AdminLoginPhase.credentials);
    });

    test('sendTwoFactorCode updates expiresIn', () async {
      repository.adminLoginResult = const Success(
        AdminLoginTwoFactorRequired(
          challengeToken: 'challenge-token',
          expiresIn: 600,
        ),
      );
      repository.adminSend2faResult = const Success(540);

      final container = createContainer();
      final notifier = container.read(adminLoginStateProvider.notifier);

      await notifier.submitCredentials(
        email: 'admin@example.com',
        password: 'Password1!',
      );

      await notifier.sendTwoFactorCode();

      expect(repository.lastAdminSend2faChallengeToken, 'challenge-token');
      expect(container.read(adminLoginStateProvider).expiresIn, 540);
    });
  });
}
