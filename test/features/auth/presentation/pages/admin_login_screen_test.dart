import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_auth_tenant.dart';
import 'package:vcare_admin/features/auth/domain/entities/admin_login_outcome.dart';
import 'package:vcare_admin/features/auth/presentation/pages/admin_login_screen.dart';
import 'package:vcare_admin/features/auth/presentation/providers/auth_repository_provider.dart';

import '../../../../fixtures/repositories/fake_auth_repository.dart';
import '../../../../helpers/in_memory_storage_service.dart';

void main() {
  group('AdminLoginScreen', () {
    late FakeAuthRepository repository;
    late InMemoryStorageService storageService;

    setUp(() {
      repository = FakeAuthRepository();
      storageService = InMemoryStorageService();
    });

    Widget buildSubject() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => repository),
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          home: const AdminLoginScreen(),
        ),
      );
    }

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

      await tester.enterText(find.byType(TextFormField).at(0), 'admin@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Choose your organization'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
    });
  });
}
