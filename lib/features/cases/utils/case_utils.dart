import 'package:intl/intl.dart';

import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';
import 'package:vcare_admin/shared/utils/date_format_utils.dart';

/// Case type labels matching web `caseTypeOptions` / `CASE_TYPES`.
const List<String> caseTypeOptions = [
  'Appeals & Grievances',
  'Benefit Navigation',
  'Bill Negotiation',
  'Care Coordination',
  'Claims Assistance',
  'Insurance Navigation',
  'Procedure Cost',
  'Provider Search',
  'RX Benefits',
];

/// Allowed file extensions for case / note attachments.
const Set<String> caseAllowedFileExtensions = {
  'pdf',
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'svg',
  'bmp',
  'tif',
  'tiff',
  'doc',
  'docx',
  'txt',
  'csv',
  'zip',
};

const int caseFileMaxCount = 10;
const int caseFileMaxSizeBytes = 25 * 1024 * 1024;

/// Web `MAX_TOTAL_UPLOAD_BYTES` — one batch may not exceed this in total.
const int caseFileMaxBatchBytes = 25 * 1024 * 1024;
const String caseFileCategory = 'REFERRAL_CASE';
const String caseFileClientCategory = 'CLIENT';
const String caseTaskCategory = 'REFERRAL';
const int caseTaskListLimit = 50;
const String noteAccessTypePrivate = 'INTERNAL';
const String noteAccessTypePublic = 'EXTERNAL';
const String defaultNoteAccessType = noteAccessTypePrivate;

/// Formats a case id into the short display number (first 8 chars, uppercased).
String formatCaseNumber(String id) {
  final trimmed = id.trim();
  if (trimmed.isEmpty) return '';
  final end = trimmed.length < 8 ? trimmed.length : 8;
  return trimmed.substring(0, end).toUpperCase();
}

/// Last 4 characters of a case number for compact display.
String formatCaseNumberShort(String caseNumber) {
  final trimmed = caseNumber.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.length <= 4) return trimmed.toUpperCase();
  return trimmed.substring(trimmed.length - 4).toUpperCase();
}

/// Last 4 characters of the raw case id, e.g. `...129f6859b7ad` -> `b7ad`.
String formatCaseIdShort(String id) {
  final trimmed = id.trim();
  if (trimmed.length <= 4) return trimmed;
  return trimmed.substring(trimmed.length - 4);
}

/// Fuzzy-match an API type string to a known case type label.
String resolveCaseTypeLabel(String? type) {
  final raw = type?.trim() ?? '';
  if (raw.isEmpty) return '';
  for (final option in caseTypeOptions) {
    if (option.toLowerCase() == raw.toLowerCase()) return option;
  }
  for (final option in caseTypeOptions) {
    if (option.toLowerCase().contains(raw.toLowerCase()) ||
        raw.toLowerCase().contains(option.toLowerCase())) {
      return option;
    }
  }
  return raw.length > 32 ? raw.substring(0, 32) : raw;
}

String mapCaseTypeLabelToApi(String label) {
  final trimmed = label.trim();
  if (trimmed.length <= 32) return trimmed;
  return trimmed.substring(0, 32);
}

/// Days since [createdAt] ISO string.
int getDaysOpen(String? createdAt) {
  if (createdAt == null || createdAt.trim().isEmpty) return 0;
  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return 0;
  final now = DateTime.now();
  final diff = now.difference(parsed.toLocal());
  return diff.inDays < 0 ? 0 : diff.inDays;
}

/// Encode a mention for API storage: `@[Name](email)`.
String formatMention(String name, String email) {
  return '@[${name.trim()}](${email.trim()})';
}

final RegExp mentionTokenRegex = RegExp(r'@\[([^\]]+)\]\(([^)]+)\)');

/// One run of note content: either plain text or a resolved mention.
class CaseNoteContentSegment {
  const CaseNoteContentSegment.text(this.value) : name = null, email = null;

  const CaseNoteContentSegment.mention({
    required this.value,
    required String this.name,
    required String this.email,
  });

  final String value;
  final String? name;
  final String? email;

  bool get isMention => name != null && email != null;
}

/// Splits stored note content into text / mention runs for rendering.
List<CaseNoteContentSegment> parseNoteMentionSegments(String content) {
  if (content.isEmpty) return const [];

  final segments = <CaseNoteContentSegment>[];
  var lastIndex = 0;

  for (final match in mentionTokenRegex.allMatches(content)) {
    if (match.start > lastIndex) {
      segments.add(
        CaseNoteContentSegment.text(content.substring(lastIndex, match.start)),
      );
    }
    segments.add(
      CaseNoteContentSegment.mention(
        value: match.group(0)!,
        name: match.group(1)!,
        email: match.group(2)!,
      ),
    );
    lastIndex = match.end;
  }

  if (lastIndex < content.length) {
    segments.add(CaseNoteContentSegment.text(content.substring(lastIndex)));
  }

  return segments;
}

final RegExp _clonedFromCaseNoteRegex = RegExp(
  r'^(cloned from case)\s+'
  r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$',
  caseSensitive: false,
);

/// Recognises the auto-generated `Cloned from case {uuid}` placeholder note.
({String labelPrefix, String caseId})? parseClonedFromCaseNote(String content) {
  final match = _clonedFromCaseNoteRegex.firstMatch(content.trim());
  if (match == null) return null;
  return (labelPrefix: match.group(1)!, caseId: match.group(2)!);
}

/// Uppercases the first letter of each word, matching the web `capitalize`
/// text transform applied to note bodies.
String capitalizeWords(String value) {
  if (value.isEmpty) return value;

  final buffer = StringBuffer();
  var atWordStart = true;

  for (final char in value.split('')) {
    if (atWordStart && char.trim().isNotEmpty) {
      buffer.write(char.toUpperCase());
      atWordStart = false;
      continue;
    }
    buffer.write(char);
    if (char.trim().isEmpty) atWordStart = true;
  }

  return buffer.toString();
}

/// Minimum note count before a summary can be generated.
const int caseNoteSummaryMinimumCount = 3;

/// Placeholder digest of the first few notes, mirroring the web summary text.
String buildCaseNoteSummary(List<CaseNote> notes) {
  if (notes.length < caseNoteSummaryMinimumCount) return '';

  final leading = notes
      .take(3)
      .map(
        (note) => note.content.length > 80
            ? note.content.substring(0, 80)
            : note.content,
      )
      .join('\n• ');
  final remaining = notes.length - 3;

  return 'Based on ${notes.length} notes:\n\n'
      '• $leading\n\n'
      '…and $remaining more note(s). Key themes include care coordination, '
      'follow-ups, and client communication.';
}

/// Toggle note access between INTERNAL and EXTERNAL.
String toggleNoteAccessType(String? accessType) {
  final value = accessType?.trim().toUpperCase();
  if (value == 'EXTERNAL' || value == 'PUBLIC') {
    return noteAccessTypePrivate;
  }
  return noteAccessTypePublic;
}

bool isPublicNoteAccessType(String? accessType) {
  final value = accessType?.trim().toUpperCase();
  return value == 'EXTERNAL' || value == 'PUBLIC';
}

/// Status of the most recently created note that has one, else [fallback].
CaseStatus resolveLatestCaseNoteStatus(
  List<CaseNote> notes,
  CaseStatus fallback,
) {
  return resolveLatestCaseNoteStatusOrNull(notes) ?? fallback;
}

/// Status of the most recently created note that has one, or null when none do.
CaseStatus? resolveLatestCaseNoteStatusOrNull(List<CaseNote> notes) {
  if (notes.isEmpty) return null;

  final newestFirst = [...notes]..sort((a, b) {
    final aMs = DateTime.tryParse(a.createdAt)?.millisecondsSinceEpoch ?? 0;
    final bMs = DateTime.tryParse(b.createdAt)?.millisecondsSinceEpoch ?? 0;
    return bMs.compareTo(aMs);
  });

  for (final note in newestFirst) {
    if (note.status != null) return note.status!;
  }
  return null;
}

/// Oldest → newest so the latest note sits at the bottom (chat-style).
List<CaseNote> sortCaseNotesChronologically(List<CaseNote> notes) {
  if (notes.length < 2) return notes;
  final sorted = [...notes];
  sorted.sort((a, b) {
    final aMs = DateTime.tryParse(a.createdAt)?.millisecondsSinceEpoch ?? 0;
    final bMs = DateTime.tryParse(b.createdAt)?.millisecondsSinceEpoch ?? 0;
    final byTime = aMs.compareTo(bMs);
    if (byTime != 0) return byTime;
    return a.id.compareTo(b.id);
  });
  return sorted;
}

String truncateWords(String value, int maxWords) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length <= maxWords) return value.trim();
  return '${parts.take(maxWords).join(' ')}…';
}

String buildCasesSubtitle(int totalCount, {bool isLoading = false}) {
  if (isLoading) return 'Loading cases…';
  if (totalCount <= 0) return 'Monitor and manage advocacy cases';
  final label = totalCount == 1 ? 'case' : 'cases';
  return '$totalCount $label';
}

/// Formats a note timestamp as `Aug 11, 2026 5:20 PM`.
String formatNoteTimestamp(String? input) {
  if (input == null || input.trim().isEmpty) return '';
  final trimmed = input.trim();
  final parsed = DateTime.tryParse(trimmed) ?? parseDisplayDate(trimmed);
  if (parsed == null) return trimmed;
  return DateFormat('MMM d, y h:mm a').format(parsed.toLocal());
}

/// Formats a task due date as `MM/dd/yyyy hh:mm a`, matching the web
/// `formatTaskDueDate`.
String formatTaskDueDate(String? input) {
  if (input == null || input.trim().isEmpty) return '';
  final trimmed = input.trim();
  final parsed = DateTime.tryParse(trimmed) ?? parseDisplayDate(trimmed);
  if (parsed == null) return trimmed;
  return DateFormat('MM/dd/yyyy hh:mm a').format(parsed.toLocal());
}

/// Formats case list dates as `MM/dd/yyyy` when parseable; otherwise raw.
String formatCaseListDate(String? input) {
  if (input == null || input.trim().isEmpty) return '';
  final trimmed = input.trim();
  final parsed = DateTime.tryParse(trimmed) ?? parseDisplayDate(trimmed);
  if (parsed == null) return trimmed;
  return DateFormat('MM/dd/yyyy').format(parsed.toLocal());
}

/// Initials from a free-form display name (e.g. created-by).
String initialsFromDisplayName(String? name) {
  final parts = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

bool isMissingCreatedByLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty || trimmed == '—';
}

bool _isMissingCreatedBy(String value) => isMissingCreatedByLabel(value);

/// Keeps nested client / created-by when a PATCH payload omits them.
ReferralCase mergeReferralCaseDetail(
  ReferralCase previous,
  ReferralCase incoming,
) {
  final previousClientUseful = previous.client.hasIdentity;
  final incomingClientUseful = incoming.client.hasIdentity;

  final ReferralCaseClient client;
  if (!incomingClientUseful && previousClientUseful) {
    client = previous.client;
  } else if (incomingClientUseful) {
    client = ReferralCaseClient(
      id: incoming.client.id.isNotEmpty
          ? incoming.client.id
          : previous.client.id,
      firstName: incoming.client.firstName.isNotEmpty
          ? incoming.client.firstName
          : previous.client.firstName,
      middleName: incoming.client.middleName ?? previous.client.middleName,
      lastName: incoming.client.lastName.isNotEmpty
          ? incoming.client.lastName
          : previous.client.lastName,
      email: incoming.client.email.isNotEmpty
          ? incoming.client.email
          : previous.client.email,
      phone: incoming.client.phone.isNotEmpty
          ? incoming.client.phone
          : previous.client.phone,
      dateOfBirth: incoming.client.dateOfBirth.isNotEmpty
          ? incoming.client.dateOfBirth
          : previous.client.dateOfBirth,
      avatarUrl: (incoming.client.avatarUrl?.trim().isNotEmpty ?? false)
          ? incoming.client.avatarUrl
          : previous.client.avatarUrl,
      profilePreviewLink:
          (incoming.client.profilePreviewLink?.trim().isNotEmpty ?? false)
          ? incoming.client.profilePreviewLink
          : previous.client.profilePreviewLink,
      membershipPlan:
          (incoming.client.membershipPlan?.trim().isNotEmpty ?? false)
          ? incoming.client.membershipPlan
          : previous.client.membershipPlan,
      bloodType: (incoming.client.bloodType?.trim().isNotEmpty ?? false)
          ? incoming.client.bloodType
          : previous.client.bloodType,
      dependentOf: (incoming.client.dependentOf?.trim().isNotEmpty ?? false)
          ? incoming.client.dependentOf
          : previous.client.dependentOf,
      address: (incoming.client.address?.trim().isNotEmpty ?? false)
          ? incoming.client.address
          : previous.client.address,
    );
  } else {
    client = incoming.client;
  }

  final preserveCreatedBy =
      !_isMissingCreatedBy(previous.createdBy) &&
      (_isMissingCreatedBy(incoming.createdBy) ||
          (incoming.createdById != null &&
              incoming.createdBy.trim() == incoming.createdById!.trim()));

  return incoming.copyWith(
    client: client,
    clientId: incoming.clientId.trim().isNotEmpty
        ? incoming.clientId
        : previous.clientId,
    createdBy: preserveCreatedBy ? previous.createdBy : incoming.createdBy,
    createdById: incoming.createdById ?? previous.createdById,
    caseNumber: incoming.caseNumber.trim().isNotEmpty
        ? incoming.caseNumber
        : previous.caseNumber,
    title: incoming.title.trim().isNotEmpty ? incoming.title : previous.title,
  );
}
