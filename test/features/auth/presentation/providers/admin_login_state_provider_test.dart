import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/features/auth/data/repositories/admin_auth_session_store.dart';
import 'package:vcare_admin/features/auth/data/repositories/auth_secure_token_store.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/password_login_lock.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_login_state_provider.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/state/admin_login_state.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';
import '../../../../fixtures/repository_fixtures.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
          adminAuthSessionStoreProvider.overrideWith(
            (ref) => AdminAuthSessionStore(
              storageService,
              tokenStore: AuthSecureTokenStore(
                storage: storageService,
                secureStore: InMemorySecureKvStore(),
              ),
            ),
          ),
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

    test('surfaces remaining password attempts on wrong password', () async {
      repository.adminLoginResult = Failure(
        HttpException(
          message: 'Invalid credentials',
          statusCode: 401,
          responseData: {'passwordTriesLeft': 2},
        ),
      );

      final container = createContainer();

      await container.read(adminLoginStateProvider.notifier).submitCredentials(
            email: 'admin@example.com',
            password: 'wrong-password',
          );

      final state = container.read(adminLoginStateProvider);
      expect(
        state.errorMessage,
        'Incorrect email or password. You have 2 login attempts remaining.',
      );
      expect(state.isAccountPasswordLocked, isFalse);
      expect(state.isSubmitting, isFalse);
    });

    test('surfaces fallback message for invalid credentials without tries',
        () async {
      repository.adminLoginResult = Failure(
        HttpException(
          message: 'Invalid credentials',
          statusCode: 401,
        ),
      );

      final container = createContainer();

      await container.read(adminLoginStateProvider.notifier).submitCredentials(
            email: 'admin@example.com',
            password: 'wrong-password',
          );

      final state = container.read(adminLoginStateProvider);
      expect(state.errorMessage, wrongPasswordFallback);
      expect(state.isAccountPasswordLocked, isFalse);
    });

    test('sets account lock support email when password locked', () async {
      repository.adminLoginResult = Failure(
        HttpException(
          message: 'Blocked',
          statusCode: 403,
          responseData: {
            'code': AuthPasswordLoginErrorCode.accountPasswordLocked,
            'supportEmail': 'help@example.com',
          },
        ),
      );

      final container = createContainer();

      await container.read(adminLoginStateProvider.notifier).submitCredentials(
            email: 'admin@example.com',
            password: 'wrong-password',
          );

      final state = container.read(adminLoginStateProvider);
      expect(state.errorMessage, isNull);
      expect(state.isAccountPasswordLocked, isTrue);
      expect(state.accountLockedSupportEmail, 'help@example.com');
      expect(state.isSubmitting, isFalse);
    });

    test('clears account lock when submitting credentials again', () async {
      repository.adminLoginResult = Failure(
        HttpException(
          message: 'Blocked',
          statusCode: 403,
          responseData: {
            'code': AuthPasswordLoginErrorCode.accountPasswordLocked,
          },
        ),
      );

      final container = createContainer();
      final notifier = container.read(adminLoginStateProvider.notifier);

      await notifier.submitCredentials(
        email: 'admin@example.com',
        password: 'wrong-password',
      );
      expect(
        container.read(adminLoginStateProvider).isAccountPasswordLocked,
        isTrue,
      );

      repository.adminLoginResult = Failure(
        HttpException(
          message: 'Invalid credentials',
          statusCode: 401,
          responseData: {'passwordTriesLeft': 4},
        ),
      );

      await notifier.submitCredentials(
        email: 'admin@example.com',
        password: 'still-wrong',
      );

      final state = container.read(adminLoginStateProvider);
      expect(state.isAccountPasswordLocked, isFalse);
      expect(state.accountLockedSupportEmail, isNull);
      expect(
        state.errorMessage,
        'Incorrect email or password. You have 4 login attempts remaining.',
      );
    });
  });
}
