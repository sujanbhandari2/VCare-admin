import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_notes_state_provider.dart';
import 'package:vcare_admin/features/cases/presentation/providers/case_repository_provider.dart';

import '../../../../fixtures/repositories/fake_case_note_repository.dart';
import '../../../../fixtures/repositories/fake_case_repository.dart';

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
    late FakeCaseRepository caseRepository;

    setUp(() {
      repository = FakeCaseNoteRepository();
      caseRepository = FakeCaseRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          caseNoteRepositoryProvider.overrideWithValue(repository),
          caseRepositoryProvider.overrideWithValue(caseRepository),
        ],
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

    test('summarizeNotes succeeds and stores summary text', () async {
      repository.fetchNotesResult = Success([
        _note(id: 'n1', content: 'Note one'),
        _note(id: 'n2', content: 'Note two'),
        _note(id: 'n3', content: 'Note three'),
        _note(id: 'n4', content: 'Note four'),
      ]);
      caseRepository.summarizeCaseNotesResult = const Success(
        'Care coordination summary',
      );

      final container = createContainer();
      final notifier = container.read(caseNotesStateProvider(_caseId).notifier);
      await notifier.fetchNotes();

      String? completedSummary;
      String? completedError;
      await notifier.summarizeNotes(
        onCompleted: (summary, error) {
          completedSummary = summary;
          completedError = error;
        },
      );

      final state = container.read(caseNotesStateProvider(_caseId));
      expect(state.summarizing, isFalse);
      expect(state.summaryText, 'Care coordination summary');
      expect(completedSummary, 'Care coordination summary');
      expect(completedError, isNull);
      expect(caseRepository.summarizeCaseNotesCallCount, 1);
      expect(caseRepository.lastSummarizeCaseId, _caseId);
      expect(caseRepository.lastSummarizeRequest?.notes, hasLength(4));
    });

    test('summarizeNotes sets failure on error', () async {
      repository.fetchNotesResult = Success([
        _note(id: 'n1', content: 'Note one'),
        _note(id: 'n2', content: 'Note two'),
        _note(id: 'n3', content: 'Note three'),
        _note(id: 'n4', content: 'Note four'),
      ]);
      caseRepository.summarizeCaseNotesResult = Failure(
        HttpException(
          message: 'Summarize failed',
          errorType: HttpErrorType.client,
        ),
      );

      final container = createContainer();
      final notifier = container.read(caseNotesStateProvider(_caseId).notifier);
      await notifier.fetchNotes();

      String? completedSummary;
      String? completedError;
      await notifier.summarizeNotes(
        onCompleted: (summary, error) {
          completedSummary = summary;
          completedError = error;
        },
      );

      final state = container.read(caseNotesStateProvider(_caseId));
      expect(state.summarizing, isFalse);
      expect(state.summarizeError, 'Summarize failed');
      expect(completedSummary, isNull);
      expect(completedError, 'Summarize failed');
    });

    test('summarizeNotes skips API when fewer than four eligible notes',
        () async {
      repository.fetchNotesResult = Success([
        _note(id: 'n1', content: 'Note one'),
        _note(id: 'n2', content: 'Note two'),
      ]);

      final container = createContainer();
      final notifier = container.read(caseNotesStateProvider(_caseId).notifier);
      await notifier.fetchNotes();

      String? completedError;
      await notifier.summarizeNotes(
        onCompleted: (_, error) => completedError = error,
      );

      expect(caseRepository.summarizeCaseNotesCallCount, 0);
      expect(completedError, contains('Min 4 notes'));
    });
  });
}
