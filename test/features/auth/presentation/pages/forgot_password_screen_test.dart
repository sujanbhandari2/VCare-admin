import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';

void main() {
  group('ForgotPasswordScreen', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();
    });

    Widget buildSubject() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          home: const ForgotPasswordScreen(),
        ),
      );
    }

    testWidgets('shows email form initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.text('Back to sign in'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(LoginTextField), 'not-an-email');
      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(repository.lastAdminForgotPasswordEmail, isNull);
    });

    testWidgets('shows sent confirmation after successful submit',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(LoginTextField), 'user@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(repository.lastAdminForgotPasswordEmail, 'user@example.com');
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('Send another link'), findsOneWidget);
    });
  });
}
