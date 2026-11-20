import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_shared_widgets.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';

void main() {
  group('ResetPasswordScreen', () {
    late FakeAuthRepository repository;

    setUp(() {
      repository = FakeAuthRepository();
    });

    Widget buildSubject({String? token}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          home: ResetPasswordScreen(token: token),
        ),
      );
    }

    testWidgets('shows invalid link message when token is missing',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
      expect(
        find.textContaining('Reset link is missing or invalid'),
        findsOneWidget,
      );
      expect(find.text('Request a new reset link'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('shows password form when token is present', (tester) async {
      await tester.pumpWidget(buildSubject(token: 'reset-token'));
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('Password requirements'), findsOneWidget);
      expect(find.text('Reset password'), findsOneWidget);
    });

    testWidgets('shows mismatch error before calling API', (tester) async {
      await tester.pumpWidget(buildSubject(token: 'reset-token'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(LoginTextField).at(0), 'Password1!');
      await tester.enterText(find.byType(LoginTextField).at(1), 'Password2!');
      await tester.ensureVisible(find.text('Reset password'));
      await tester.tap(find.text('Reset password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(repository.lastResetPasswordToken, isNull);
    });
  });
}
