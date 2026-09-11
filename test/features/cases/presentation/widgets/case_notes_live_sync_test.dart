import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';
import 'package:vcare_admin/features/cases/presentation/widgets/case_notes_live_sync.dart';

import '../../../../fixtures/repositories/fake_case_note_repository.dart';

const _caseId = 'case-1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCaseNoteRepository repository;

  setUp(() {
    repository = FakeCaseNoteRepository()
      ..fetchNotesResult = Success(const [
        CaseNote(
          id: 'n1',
          content: 'Hello',
          createdAt: '2026-08-28T00:00:00.000Z',
        ),
      ]);
  });

  Future<GoRouter> pumpSync(
    WidgetTester tester, {
    String location = '/cases/$_caseId',
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/cases',
          builder: (_, __) => const Scaffold(body: Text('cases-list')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => CaseNotesLiveSync(
                caseId: state.pathParameters['id'] ?? '',
                child: const Scaffold(body: Text('case-detail')),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/clients',
          builder: (_, __) => const Scaffold(body: Text('clients')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [caseNoteRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    return router;
  }

  CaseNotesState notesNotifier(WidgetTester tester) {
    final context = tester.element(find.byType(CaseNotesLiveSync));
    return ProviderScope.containerOf(
      context,
    ).read(caseNotesStateProvider(_caseId).notifier);
  }

  testWidgets('starts streaming while case detail is active', (tester) async {
    await pumpSync(tester);

    expect(notesNotifier(tester).isStreamingNotes, isTrue);
    expect(find.text('case-detail'), findsOneWidget);
  });

  testWidgets('stops streaming when the detail route is popped', (
    tester,
  ) async {
    final router = await pumpSync(tester);
    final notifier = notesNotifier(tester);
    expect(notifier.isStreamingNotes, isTrue);

    router.go('/cases');
    await tester.pumpAndSettle();

    expect(find.text('cases-list'), findsOneWidget);
    expect(notifier.isStreamingNotes, isFalse);
  });

  testWidgets('stops streaming when the screen changes', (tester) async {
    final router = await pumpSync(tester);
    final notifier = notesNotifier(tester);
    expect(notifier.isStreamingNotes, isTrue);

    router.go('/clients');
    await tester.pumpAndSettle();

    expect(find.text('clients'), findsOneWidget);
    expect(notifier.isStreamingNotes, isFalse);
  });
}
