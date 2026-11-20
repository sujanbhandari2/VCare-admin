/// One note entry in the AI summarize request body.
///
/// Parity with web `SummarizeReferralCaseNoteInput`.
class CaseNoteSummarizeInput {
  const CaseNoteSummarizeInput({
    required this.note,
    this.authorName,
  });

  final String note;
  final String? authorName;

  Map<String, dynamic> toJson() {
    final trimmedName = authorName?.trim();
    return {
      'note': note,
      if (trimmedName != null && trimmedName.isNotEmpty)
        'createdBy': {'name': trimmedName},
    };
  }
}

/// Body for `POST /api/v1/referral-cases/{id}/summarize`.
///
/// Parity with web `SummarizeReferralCaseBody`.
class CaseNoteSummarizeRequest {
  const CaseNoteSummarizeRequest({this.notes = const []});

  final List<CaseNoteSummarizeInput> notes;

  Map<String, dynamic> toJson() {
    return {
      'notes': notes.map((note) => note.toJson()).toList(growable: false),
    };
  }
}
