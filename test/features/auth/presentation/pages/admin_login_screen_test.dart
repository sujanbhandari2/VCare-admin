import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/domain/password_login_lock.dart';
import 'package:vcare_admin/features/auth/presentation/pages/admin_login_screen.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_account_locked_message.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_inline_error_banner.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';
import 'package:vcare_admin/features/biometric_login/presentation/providers/biometric_login_repository_provider.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';
import '../../../../fixtures/repositories/fake_biometric_login_repository.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('AdminLoginScreen', () {
    late FakeAuthRepository repository;
    late FakeBiometricLoginRepository biometricRepository;
    late InMemoryStorageService storageService;

    setUp(() {
      repository = FakeAuthRepository();
      biometricRepository = FakeBiometricLoginRepository();
      storageService = InMemoryStorageService();
    });

    Widget buildSubject() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
          biometricLoginRepositoryProvider.overrideWithValue(
            biometricRepository,
          ),
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          home: const AdminLoginScreen(),
        ),
      );
    }

    testWidgets('shows LoginFooter terms copy on credentials step',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(LoginFooter), findsOneWidget);
      expect(find.textContaining('Terms of Service'), findsOneWidget);
      expect(find.textContaining('Privacy Policy'), findsOneWidget);
      expect(find.textContaining('HIPAA Compliant'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty credentials', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(repository.lastAdminLoginEmail, isNull);
    });

    testWidgets('shows tenant picker when tenant selection is required',
        (tester) async {
      repository.adminLoginResult = Success(
        AdminLoginTenantSelectionRequired(const [
          TenantOption(slug: 'acme', name: 'Acme Corp'),
        ]),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'admin@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password1!');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Select organization'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.byType(LoginFooter), findsOneWidget);
    });

    testWidgets('shows two-factor form with remember-me when challenge required',
        (tester) async {
      repository.adminLoginResult = const Success(
        AdminLoginTwoFactorRequired(
          challengeToken: 'challenge-token',
          expiresIn: 600,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'admin@example.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'Password1!');
      await tester.tap(find.text('Sign in'));
      // Avoid pumpAndSettle — OTP caret animation + resend timer never settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Enter verification code'), findsOneWidget);
      expect(find.text('Remember this code for 7 days'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.textContaining('admin@example.com'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.byType(LoginFooter), findsOneWidget);
    });

    testWidgets('shows remaining attempts banner on wrong password',
        (tester) async {
      repository.adminLoginResult = Failure(
        HttpException(
          message: 'Invalid credentials',
          statusCode: 401,
          responseData: {'passwordTriesLeft': 3},
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'admin@example.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginInlineErrorBanner), findsOneWidget);
      expect(
        find.text(
          'Incorrect email or password. You have 3 login attempts remaining.',
        ),
        findsOneWidget,
      );
      expect(find.byType(LoginAccountLockedMessage), findsNothing);
    });

    testWidgets('shows locked message and disables sign in when locked',
        (tester) async {
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

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).at(0),
        'admin@example.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginAccountLockedMessage), findsOneWidget);
      expect(find.textContaining('help@example.com'), findsOneWidget);
      expect(
        find.textContaining(
          'Your account has been blocked due to too many failed login attempts',
        ),
        findsOneWidget,
      );
      expect(find.byType(LoginInlineErrorBanner), findsNothing);

      final signInButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Sign in'),
      );
      expect(signInButton.onPressed, isNull);
    });
  });
}
