import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';

final _statusChangeNoteRegex = RegExp(
  r'^Status changed from\s+(.+?)\s+to\s+(.+?)\s*$',
  caseSensitive: false,
);

final _statusSetNoteRegex = RegExp(
  r'^Status set to\s+(.+?)\s*$',
  caseSensitive: false,
);

final _caseStatusUpdatedNoteRegex = RegExp(
  r'^Case status updated to\s+(.+?)\s*$',
  caseSensitive: false,
);

/// System or audit lines that describe case workflow status (included in AI
/// summarize).
///
/// Parity with web `isStatusChangeAuditNote`.
bool isStatusChangeAuditNote(String content) {
  final trimmed = content.trim();
  if (trimmed.isEmpty) return false;
  return _statusChangeNoteRegex.hasMatch(trimmed) ||
      _statusSetNoteRegex.hasMatch(trimmed) ||
      _caseStatusUpdatedNoteRegex.hasMatch(trimmed);
}

/// Turn API enums like REQUESTED / IN_PROGRESS into "Requested" / "In Progress".
///
/// Parity with web `formatCaseStatusDisplayLabel`.
String formatCaseStatusDisplayLabel(String? status) {
  if (status == null || status.trim().isEmpty) return '';

  final trimmed = status.trim();
  final normalized = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  const labels = <String, String>{
    'new': 'New',
    'requested': 'Requested',
    'in_progress': 'In Progress',
    'closed': 'Closed',
    'deleted': 'Deleted',
  };
  if (labels.containsKey(normalized)) {
    return labels[normalized]!;
  }

  // Known API enums only — do not use CaseStatus.fromApi (defaults unknown → New).
  switch (trimmed.toUpperCase()) {
    case 'NEW':
      return CaseStatus.newCase.label;
    case 'REQUESTED':
    case 'OPEN':
      return CaseStatus.requested.label;
    case 'IN_PROGRESS':
    case 'IN PROGRESS':
    case 'ACTIVE':
      return CaseStatus.inProgress.label;
    case 'CLOSED':
    case 'RESOLVED':
    case 'COMPLETED':
      return CaseStatus.closed.label;
    case 'DELETED':
      return CaseStatus.deleted.label;
  }

  // Title-case unknown custom statuses (e.g. "CN - Navigation1").
  return trimmed
      .replaceAll('_', ' ')
      .toLowerCase()
      .replaceAllMapped(
        RegExp(r'\b\w'),
        (match) => match.group(0)!.toUpperCase(),
      );
}

/// Rewrite system notes like "Status changed from REQUESTED to IN_PROGRESS"
/// into "Status changed from Requested to In Progress".
///
/// Parity with web `formatStatusChangeNoteContent`.
String formatStatusChangeNoteContent(String content) {
  final trimmed = content.trim();

  final changeMatch = _statusChangeNoteRegex.firstMatch(trimmed);
  if (changeMatch != null) {
    final fromLabel = formatCaseStatusDisplayLabel(changeMatch.group(1));
    final toLabel = formatCaseStatusDisplayLabel(changeMatch.group(2));
    return 'Status changed from $fromLabel to $toLabel';
  }

  final setMatch = _statusSetNoteRegex.firstMatch(trimmed);
  if (setMatch != null) {
    final statusLabel = formatCaseStatusDisplayLabel(setMatch.group(1));
    return 'Status set to $statusLabel';
  }

  final updatedMatch = _caseStatusUpdatedNoteRegex.firstMatch(trimmed);
  if (updatedMatch != null) {
    final statusLabel = formatCaseStatusDisplayLabel(updatedMatch.group(1));
    return 'Case status updated to $statusLabel';
  }

  return content;
}

/// Parity with web `isSystemCaseNoteSource`.
bool isSystemCaseNoteSource(String? source) {
  return source?.trim().toUpperCase() == 'SYSTEM';
}
