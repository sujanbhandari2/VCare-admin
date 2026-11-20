import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note_summarize.dart';
import 'package:vcare_admin/features/cases/utils/case_note_status_audit.dart';
import 'package:vcare_admin/features/cases/utils/case_note_timeline.dart';

/// Minimum eligible note count before summarize is enabled.
///
/// Parity with web `MIN_CASE_NOTES_FOR_SUMMARIZE`.
const int minCaseNotesForSummarize = 4;

bool _isCaseWorkflowStatusNote(CaseNote note) {
  return isStatusChangeAuditNote(note.content);
}

bool _isNoteEligibleForSummarize(CaseNote note) {
  if (_isCaseWorkflowStatusNote(note)) {
    return note.content.trim().isNotEmpty;
  }

  if (note.isSystemGenerated) {
    return false;
  }

  if (isSystemCaseNoteSource(note.source)) {
    return false;
  }

  return note.content.trim().isNotEmpty;
}

String _noteTextForSummarize(CaseNote note) {
  if (isStatusChangeAuditNote(note.content)) {
    return formatStatusChangeNoteContent(note.content);
  }

  return note.content.trim();
}

/// Builds the summarize API body from currently loaded timeline notes.
///
/// Parity with web `mapNotesForSummarize`.
CaseNoteSummarizeRequest mapNotesForSummarize(List<CaseNote> notes) {
  final eligible = filterCaseNotesForTimeline(notes)
      .where(_isNoteEligibleForSummarize)
      .toList(growable: false);

  return CaseNoteSummarizeRequest(
    notes: eligible
        .map(
          (note) => CaseNoteSummarizeInput(
            note: _noteTextForSummarize(note),
            authorName: note.authorName,
          ),
        )
        .toList(growable: false),
  );
}

/// Parity with web `countNotesEligibleForSummarize`.
int countNotesEligibleForSummarize(List<CaseNote> notes) {
  return filterCaseNotesForTimeline(notes)
      .where(_isNoteEligibleForSummarize)
      .length;
}

/// Parity with web `hasEnoughCaseNotesForSummarize`.
bool hasEnoughCaseNotesForSummarize(int eligibleNoteCount) {
  return eligibleNoteCount >= minCaseNotesForSummarize;
}

/// Parity with web `summarizeNotesButtonTooltip`.
String? summarizeNotesButtonTooltip(int eligibleNoteCount) {
  if (hasEnoughCaseNotesForSummarize(eligibleNoteCount)) {
    return null;
  }

  return 'Min $minCaseNotesForSummarize notes required for summary';
}
