import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';

/// Client portal uploads from the case Files tab are stored as notes with
/// attachments and no text. They belong on the Files tab only, not in the
/// notes conversation.
///
/// Parity with web `shouldShowCaseNoteInTimeline`.
bool shouldShowCaseNoteInTimeline(CaseNote note) {
  if (note.isDeleted) {
    return true;
  }

  if (note.content.trim().isNotEmpty) {
    return true;
  }

  return note.files.isEmpty;
}

/// Parity with web `filterCaseNotesForTimeline`.
List<CaseNote> filterCaseNotesForTimeline(List<CaseNote> notes) {
  return notes.where(shouldShowCaseNoteInTimeline).toList(growable: false);
}
