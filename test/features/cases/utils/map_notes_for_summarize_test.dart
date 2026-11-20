import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/utils/map_notes_for_summarize.dart';

CaseNote _buildNote({
  String id = 'note-1',
  String authorName = 'Jane Advocate',
  String content = 'Follow up with provider',
  String? source,
  bool isSystemGenerated = false,
  List<CaseNoteFile> files = const [],
}) {
  return CaseNote(
    id: id,
    authorName: authorName,
    authorInitials: 'JA',
    content: content,
    createdAt: '2026-08-11T05:58:00.000Z',
    source: source,
    isSystemGenerated: isSystemGenerated,
    files: files,
  );
}

void main() {
  group('mapNotesForSummarize', () {
    test('maps user notes with author names', () {
      final result = mapNotesForSummarize([
        _buildNote(id: 'n1', content: 'First note'),
        _buildNote(
          id: 'n2',
          authorName: 'Padam Admin',
          content: 'Second note',
        ),
      ]);

      expect(result.notes, hasLength(2));
      expect(result.notes[0].note, 'First note');
      expect(result.notes[0].authorName, 'Jane Advocate');
      expect(result.notes[1].note, 'Second note');
      expect(result.notes[1].authorName, 'Padam Admin');
    });

    test('includes workflow status notes but excludes other system and empty notes',
        () {
      final result = mapNotesForSummarize([
        _buildNote(
          isSystemGenerated: true,
          content: 'Status changed from REQUESTED to IN_PROGRESS',
        ),
        _buildNote(
          source: 'SYSTEM',
          content: 'Case assigned to default case assignee.',
        ),
        _buildNote(
          source: 'SYSTEM',
          content: 'Status changed from REQUESTED to IN_PROGRESS',
          authorName: 'Padam Thapa',
        ),
        _buildNote(content: 'Status changed from REQUESTED to IN_PROGRESS'),
        _buildNote(content: '   '),
        _buildNote(id: 'keep', content: 'Keep me'),
      ]);

      expect(result.notes, hasLength(4));
      expect(result.notes[0].note, 'Status changed from Requested to In Progress');
      expect(result.notes[0].authorName, 'Jane Advocate');
      expect(result.notes[1].note, 'Status changed from Requested to In Progress');
      expect(result.notes[1].authorName, 'Padam Thapa');
      expect(result.notes[2].note, 'Status changed from Requested to In Progress');
      expect(result.notes[2].authorName, 'Jane Advocate');
      expect(result.notes[3].note, 'Keep me');
      expect(result.notes[3].authorName, 'Jane Advocate');

      expect(
        countNotesEligibleForSummarize([
          _buildNote(
            source: 'SYSTEM',
            content: 'Case assigned to default case assignee.',
          ),
          _buildNote(
            source: 'SYSTEM',
            content: 'Case status updated to CN - Navigation1',
          ),
          _buildNote(id: 'keep', content: 'Keep me'),
        ]),
        2,
      );
    });

    test('excludes file-only attachment notes from timeline and summarize', () {
      final result = mapNotesForSummarize([
        _buildNote(
          id: 'file-only',
          content: '',
          files: const [
            CaseNoteFile(id: 'f1', name: 'doc.pdf', url: 'https://x/doc.pdf'),
          ],
        ),
        _buildNote(id: 'keep', content: 'Keep me'),
      ]);

      expect(result.notes, hasLength(1));
      expect(result.notes.single.note, 'Keep me');
    });
  });

  group('hasEnoughCaseNotesForSummarize', () {
    test('requires at least $minCaseNotesForSummarize eligible notes', () {
      expect(hasEnoughCaseNotesForSummarize(0), isFalse);
      expect(
        hasEnoughCaseNotesForSummarize(minCaseNotesForSummarize - 1),
        isFalse,
      );
      expect(hasEnoughCaseNotesForSummarize(minCaseNotesForSummarize), isTrue);
      expect(
        hasEnoughCaseNotesForSummarize(minCaseNotesForSummarize + 1),
        isTrue,
      );
    });
  });

  group('summarizeNotesButtonTooltip', () {
    test('shows min-notes message until enough eligible notes', () {
      expect(
        summarizeNotesButtonTooltip(0),
        'Min $minCaseNotesForSummarize notes required for summary',
      );
      expect(
        summarizeNotesButtonTooltip(2),
        'Min $minCaseNotesForSummarize notes required for summary',
      );
      expect(
        summarizeNotesButtonTooltip(minCaseNotesForSummarize),
        isNull,
      );
    });
  });
}
