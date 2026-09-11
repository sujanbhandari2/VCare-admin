import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';

import '../../../../fixtures/repositories/fake_case_note_repository.dart';

const _caseId = 'case-1';

CaseNote _note({required String id, String content = 'Hello'}) {
  return CaseNote(
    id: id,
    content: content,
    createdAt: '2026-08-28T00:00:00.000Z',
    authorName: 'Alex',
  );
}

void main() {
  group('CaseNotesState', () {
    late FakeCaseNoteRepository repository;

    setUp(() {
      repository = FakeCaseNoteRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [caseNoteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('silent fetch updates notes without entering loading', () async {
      repository.fetchNotesResult = Success([_note(id: 'n1')]);
      final container = createContainer();
      final notifier = container.read(caseNotesStateProvider(_caseId).notifier);

      notifier.startStreamingNotes();
      await notifier.fetchNotes(silent: true);

      final state = container.read(caseNotesStateProvider(_caseId));
      expect(state.fetching, isFalse);
      expect(state.isInitialLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.notes, hasLength(1));
      expect(state.notes.single.id, 'n1');
    });

    test('silent fetch failure keeps existing notes and skips error', () async {
      repository.fetchNotesResult = Success([_note(id: 'n1')]);
      final container = createContainer();
      final notifier = container.read(caseNotesStateProvider(_caseId).notifier);
      await notifier.fetchNotes();

      repository.fetchNotesResult = Failure(
        HttpException(message: 'Network error'),
      );
      notifier.startStreamingNotes();
      await notifier.fetchNotes(silent: true);

      final state = container.read(caseNotesStateProvider(_caseId));
      expect(state.notes.single.id, 'n1');
      expect(state.error, isNull);
      expect(state.fetching, isFalse);
    });

    test('silent fetch with unchanged notes does not replace state', () async {
      repository.fetchNotesResult = Success([_note(id: 'n1')]);
      final container = createContainer();
      final notifier = container.read(caseNotesStateProvider(_caseId).notifier);
      await notifier.fetchNotes();
      final before = container.read(caseNotesStateProvider(_caseId));

      notifier.startStreamingNotes();
      await notifier.fetchNotes(silent: true);

      expect(
        identical(before, container.read(caseNotesStateProvider(_caseId))),
        isTrue,
      );
    });

    test('streams notes every 3 seconds and stops when asked', () {
      repository.fetchNotesResult = Success([_note(id: 'n1')]);

      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(
          caseNotesStateProvider(_caseId).notifier,
        );

        notifier.startStreamingNotes();
        expect(notifier.isStreamingNotes, isTrue);
        expect(repository.fetchNotesCount, 0);

        async.elapse(caseNotesStreamInterval);
        async.flushMicrotasks();
        expect(repository.fetchNotesCount, 1);
        expect(
          container.read(caseNotesStateProvider(_caseId)).fetching,
          isFalse,
        );

        repository.fetchNotesResult = Success([
          _note(id: 'n1'),
          _note(id: 'n2', content: 'Next'),
        ]);
        async.elapse(caseNotesStreamInterval);
        async.flushMicrotasks();
        expect(repository.fetchNotesCount, 2);
        expect(
          container.read(caseNotesStateProvider(_caseId)).notes,
          hasLength(2),
        );

        notifier.stopStreamingNotes();
        expect(notifier.isStreamingNotes, isFalse);
        async.elapse(caseNotesStreamInterval * 2);
        async.flushMicrotasks();
        expect(repository.fetchNotesCount, 2);
      });
    });

    test('stops streaming when the provider is disposed', () {
      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(
          caseNotesStateProvider(_caseId).notifier,
        );
        notifier.startStreamingNotes();

        container.dispose();
        async.elapse(caseNotesStreamInterval);
        async.flushMicrotasks();
        expect(repository.fetchNotesCount, 0);
      });
    });
  });
}
