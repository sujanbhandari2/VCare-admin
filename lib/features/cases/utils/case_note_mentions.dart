import 'package:vcare_admin/features/cases/utils/case_utils.dart';

/// Mention metadata tracked while editing a note in the composer.
class CaseMentionRecord {
  const CaseMentionRecord({required this.name, required this.email});

  final String name;
  final String email;
}

/// Active `@` query while the mention picker is open.
class ActiveMentionQuery {
  const ActiveMentionQuery({
    required this.start,
    required this.query,
    required this.end,
  });

  final int start;
  final String query;
  final int end;
}

/// Composer text segment — plain text or a resolved in-editor mention.
class CaseComposerMentionSegment {
  const CaseComposerMentionSegment.text(this.value)
      : name = null,
        email = null,
        isMention = false;

  const CaseComposerMentionSegment.mention({
    required this.value,
    required this.name,
    required this.email,
  }) : isMention = true;

  final String value;
  final String? name;
  final String? email;
  final bool isMention;
}

class CaseComposerMentionRange {
  const CaseComposerMentionRange({
    required this.start,
    required this.end,
    required this.name,
    required this.email,
    required this.token,
  });

  final int start;
  final int end;
  final String name;
  final String email;
  final String token;
}

({String text, List<CaseMentionRecord> mentions}) rawToComposerText(
  String raw,
) {
  final mentions = <CaseMentionRecord>[];
  final text = raw.replaceAllMapped(mentionTokenRegex, (match) {
    final name = match.group(1)!.trim();
    final email = match.group(2)!.trim();
    mentions.add(CaseMentionRecord(name: name, email: email));
    return formatComposerMention(name);
  });
  return (text: text, mentions: mentions);
}

String composerToRaw(String text, List<CaseMentionRecord> mentions) {
  final ranges = getComposerMentionRanges(text, mentions);
  if (ranges.isEmpty) return text;

  final buffer = StringBuffer();
  var index = 0;
  for (final range in ranges) {
    buffer.write(text.substring(index, range.start));
    buffer.write(formatMention(range.name, range.email));
    index = range.end;
  }
  buffer.write(text.substring(index));
  return buffer.toString();
}

String formatComposerMention(String name) => name.trim();

bool _isMentionBoundary(String? char) {
  if (char == null || char.isEmpty) return true;
  return RegExp(r'\s').hasMatch(char);
}

ActiveMentionQuery? findActiveMentionQuery(
  String text,
  int cursor,
  List<CaseMentionRecord> mentions,
) {
  final safeCursor = cursor.clamp(0, text.length);
  final beforeCursor = text.substring(0, safeCursor);
  final atIndex = beforeCursor.lastIndexOf('@');
  if (atIndex == -1) return null;

  if (!_isMentionBoundary(atIndex > 0 ? beforeCursor[atIndex - 1] : null)) {
    return null;
  }

  if (findComposerMentionContaining(text, atIndex, mentions) != null) {
    return null;
  }

  final afterAt = beforeCursor.substring(atIndex + 1);
  if (afterAt.startsWith('[') ||
      afterAt.contains(']') ||
      afterAt.contains('(')) {
    return null;
  }

  if (RegExp(r'\s').hasMatch(afterAt)) return null;

  return ActiveMentionQuery(
    start: atIndex,
    query: afterAt,
    end: safeCursor,
  );
}

({String nextText, int nextCursor}) insertComposerMentionAtQuery(
  String text,
  ActiveMentionQuery query,
  String name,
) {
  final label = formatComposerMention(name);
  final before = text.substring(0, query.start);
  var after = text.substring(query.end);
  final spaceBefore =
      before.isNotEmpty && !RegExp(r'\s$').hasMatch(before) ? ' ' : '';

  // Drop any whitespace already typed after the @query so we insert one boundary.
  if (after.isNotEmpty && RegExp(r'^\s').hasMatch(after)) {
    after = after.replaceFirst(RegExp(r'^\s+'), '');
  }

  const boundary = ' ';
  final nextText = '$before$spaceBefore$label$boundary$after';
  final labelStart = before.length + spaceBefore.length;
  final nextCursor = labelStart + label.length + boundary.length;

  return (
    nextText: nextText,
    nextCursor: nextCursor.clamp(0, nextText.length),
  );
}

List<CaseComposerMentionRange> getComposerMentionRanges(
  String text,
  List<CaseMentionRecord> mentions,
) {
  final ranges = <CaseComposerMentionRange>[];
  final sorted = [...mentions]..sort((a, b) => b.name.length.compareTo(a.name.length));

  for (final mention in sorted) {
    final label = formatComposerMention(mention.name);
    if (label.isEmpty) continue;

    var index = 0;
    while (index < text.length) {
      final found = text.indexOf(label, index);
      if (found == -1) break;

      final before = found > 0 ? text[found - 1] : null;
      if (!_isMentionBoundary(before)) {
        index = found + 1;
        continue;
      }

      final overlaps = ranges.any(
        (range) => found < range.end && found + label.length > range.start,
      );
      if (overlaps) {
        index = found + 1;
        continue;
      }

      ranges.add(
        CaseComposerMentionRange(
          start: found,
          end: found + label.length,
          name: mention.name,
          email: mention.email,
          token: label,
        ),
      );
      index = found + label.length;
    }
  }

  ranges.sort((a, b) => a.start.compareTo(b.start));
  return ranges;
}

CaseComposerMentionRange? findComposerMentionContaining(
  String text,
  int position,
  List<CaseMentionRecord> mentions,
) {
  final safePosition = position.clamp(0, text.length);
  for (final range in getComposerMentionRanges(text, mentions)) {
    if (safePosition > range.start && safePosition <= range.end) {
      return range;
    }
  }
  return null;
}

List<CaseMentionRecord> pruneMentionsInText(
  String text,
  List<CaseMentionRecord> mentions,
) {
  final ranges = getComposerMentionRanges(text, mentions);
  final active = ranges
      .map((range) => '${range.name}\u0000${range.email}')
      .toSet();
  return mentions
      .where((mention) => active.contains('${mention.name}\u0000${mention.email}'))
      .toList();
}

String sanitizeBrokenMentionTokens(String text) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < text.length) {
    final atIndex = text.indexOf('@', index);
    if (atIndex == -1) {
      buffer.write(text.substring(index));
      break;
    }

    buffer.write(text.substring(index, atIndex));
    final candidate = text.substring(atIndex);
    final complete = mentionTokenRegex.firstMatch(candidate);

    if (complete != null && complete.start == 0) {
      buffer.write(formatComposerMention(complete.group(1)!));
      index = atIndex + complete.group(0)!.length;
      continue;
    }

    if (candidate.startsWith('@[')) {
      index = atIndex + 2;
      while (index < text.length && !_isMentionBoundary(text[index])) {
        index += 1;
      }
      continue;
    }

    buffer.write('@');
    index = atIndex + 1;
  }

  return buffer.toString();
}

String cleanupOrphanComposerAtSigns(
  String text,
  List<CaseMentionRecord> mentions,
  int cursor,
) {
  final validRanges = getComposerMentionRanges(text, mentions);
  final activeQuery = findActiveMentionQuery(text, cursor, mentions);
  final buffer = StringBuffer();
  var index = 0;

  while (index < text.length) {
    if (text[index] != '@') {
      buffer.write(text[index]);
      index += 1;
      continue;
    }

    final inValidMention = validRanges.any(
      (range) => index >= range.start && index < range.end,
    );
    if (inValidMention) {
      CaseComposerMentionRange? rangeAtStart;
      for (final range in validRanges) {
        if (range.start == index) {
          rangeAtStart = range;
          break;
        }
      }
      if (rangeAtStart != null) {
        buffer.write(text.substring(index, rangeAtStart.end));
        index = rangeAtStart.end;
        continue;
      }
    }

    final isActiveTyping = activeQuery != null &&
        index == activeQuery.start &&
        cursor >= activeQuery.start &&
        cursor <= activeQuery.end;

    if (isActiveTyping) {
      buffer.write(text.substring(index, activeQuery.end));
      index = activeQuery.end;
      continue;
    }

    index += 1;
    while (index < text.length && !_isMentionBoundary(text[index])) {
      index += 1;
    }
  }

  return buffer.toString();
}

List<CaseComposerMentionSegment> parseComposerMentions(
  String text,
  List<CaseMentionRecord> mentions,
) {
  if (text.isEmpty) return const [];

  final ranges = getComposerMentionRanges(text, mentions);
  if (ranges.isEmpty) {
    return [CaseComposerMentionSegment.text(text)];
  }

  final segments = <CaseComposerMentionSegment>[];
  var index = 0;

  for (final range in ranges) {
    if (range.start > index) {
      segments.add(
        CaseComposerMentionSegment.text(text.substring(index, range.start)),
      );
    }
    segments.add(
      CaseComposerMentionSegment.mention(
        value: range.token,
        name: range.name,
        email: range.email,
      ),
    );
    index = range.end;
  }

  if (index < text.length) {
    segments.add(CaseComposerMentionSegment.text(text.substring(index)));
  }

  return segments;
}