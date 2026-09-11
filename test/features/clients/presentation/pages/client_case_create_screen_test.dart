import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_creation_draft.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/features/clients/presentation/pages/client_case_create_screen.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';

import '../../../../fixtures/repositories/fake_case_repository.dart';
import '../../../../fixtures/repositories/fake_client_repository.dart';

void main() {
  const prefill = CaseCreationClient(
    id: 'client-1',
    firstName: 'Jane',
    lastName: 'Doe',
    email: 'jane@example.com',
    phone: '555-0100',
  );

  Widget wrap({
    required FakeCaseRepository cases,
    required FakeClientRepository clients,
  }) {
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Client detail')),
        ),
        GoRoute(
          path: '/create',
          builder: (_, _) => const ClientCaseCreateScreen(
            clientId: 'client-1',
            prefillClient: prefill,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        caseRepositoryProvider.overrideWith((ref) => cases),
        clientRepositoryProvider.overrideWith((ref) => clients),
      ],
      child: MaterialApp.router(
        theme: ThemeData(extensions: [VCareThemeExtension.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  FilledButton filledButtonWithLabel(WidgetTester tester, String label) {
    return tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(FilledButton),
      ),
    );
  }

  testWidgets('locks client and uses two-step Note / Case Details flow', (
    tester,
  ) async {
    final cases = FakeCaseRepository();
    final clients = FakeClientRepository();

    await tester.pumpWidget(wrap(cases: cases, clients: clients));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsWidgets);
    expect(find.text('Change'), findsNothing);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Case Details'), findsOneWidget);
    expect(find.text('Client'), findsNothing);
    expect(find.text('Add a note'), findsOneWidget);

    await tapVisible(tester, find.text('Next'));

    expect(find.text('Case details'), findsOneWidget);
    expect(filledButtonWithLabel(tester, 'Review').onPressed, isNull);

    await tapVisible(tester, find.text('Care Coordination'));

    expect(filledButtonWithLabel(tester, 'Review').onPressed, isNotNull);
  });

  testWidgets('submits NEW case with type, assignee, and INTERNAL note', (
    tester,
  ) async {
    final cases = FakeCaseRepository();
    final clients = FakeClientRepository();

    await tester.pumpWidget(wrap(cases: cases, clients: clients));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Needs care coordination help',
    );
    await tester.pumpAndSettle();

    // Assignees are preloaded when the note step opens.
    expect(find.text('Alex Advocate'), findsOneWidget);

    await tapVisible(tester, find.text('Alex Advocate'));
    await tapVisible(tester, find.text('Next'));
    await tapVisible(tester, find.text('Care Coordination'));
    await tapVisible(tester, find.text('Review'));

    expect(find.text('Review & create'), findsOneWidget);
    expect(find.text('Care Coordination'), findsOneWidget);
    expect(find.text('Alex Advocate'), findsOneWidget);
    expect(find.text('Needs care coordination help'), findsOneWidget);

    await tapVisible(tester, find.text('Confirm & Create'));

    final body = cases.lastCreateBody;
    expect(body, isNotNull);
    expect(body!.clientId, 'client-1');
    expect(body.status, 'NEW');
    expect(body.type, mapCaseTypeLabelToApi('Care Coordination'));
    expect(body.assignedTo, 'user-1');
    expect(body.notes, isNotNull);
    expect(body.notes, hasLength(1));
    expect(body.notes!.first.note, 'Needs care coordination help');
    expect(body.notes!.first.accessType, defaultNoteAccessType);
  });
}
