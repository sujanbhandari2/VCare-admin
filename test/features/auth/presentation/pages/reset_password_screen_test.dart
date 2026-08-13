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

    testWidgets('shows invalid link when token is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Invalid reset link'), findsOneWidget);
      expect(find.text('Back to sign in'), findsOneWidget);
    });

    testWidgets('shows password form when token is present', (tester) async {
      await tester.pumpWidget(buildSubject(token: 'reset-token'));
      await tester.pumpAndSettle();

      expect(find.text('Create a new password'), findsOneWidget);
      expect(find.text('Reset password'), findsOneWidget);
    });

    testWidgets('shows mismatch error before calling API', (tester) async {
      await tester.pumpWidget(buildSubject(token: 'reset-token'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(LoginTextField).at(0), 'Password1!');
      await tester.enterText(find.byType(LoginTextField).at(1), 'Password2!');
      await tester.tap(find.text('Reset password'));
      await tester.pump();

      expect(find.text("Passwords don't match."), findsOneWidget);
      expect(repository.lastResetPasswordToken, isNull);
    });
  });
}
