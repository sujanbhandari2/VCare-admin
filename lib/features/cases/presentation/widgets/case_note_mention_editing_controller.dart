import 'package:flutter/widgets.dart';

import 'package:vcare_admin/features/cases/utils/case_note_mentions.dart';

/// Text controller that shows mention labels in the composer and emits `@[Name](email)` for the API.
class CaseNoteMentionEditingController extends TextEditingController {
  CaseNoteMentionEditingController({String? text}) : super(text: '') {
    if (text != null && text.isNotEmpty) {
      final parsed = rawToComposerText(text);
      _mentions = List.of(parsed.mentions);
      super.text = parsed.text;
    }
  }

  List<CaseMentionRecord> _mentions = [];
  bool _suppressSync = false;

  List<CaseMentionRecord> get mentions => List.unmodifiable(_mentions);

  /// Storage/API representation of the current draft.
  String get rawText => composerToRaw(text, _mentions);

  void insertMention({
    required String name,
    required String email,
    required ActiveMentionQuery query,
  }) {
    final result = insertComposerMentionAtQuery(text, query, name);
    final nextMentions = pruneMentionsInText(result.nextText, [
      ..._mentions,
      CaseMentionRecord(name: name.trim(), email: email.trim()),
    ]);
    _mentions = nextMentions;
    _suppressSync = true;
    value = TextEditingValue(
      text: result.nextText,
      selection: TextSelection.collapsed(offset: result.nextCursor),
    );
    _suppressSync = false;
  }

  @override
  set value(TextEditingValue newValue) {
    if (_suppressSync) {
      super.value = newValue;
      return;
    }
    _applyValueChange(newValue);
  }

  void _applyValueChange(TextEditingValue incoming) {
    final selection = incoming.selection;
    final cursor = selection.isValid
        ? selection.extentOffset.clamp(0, incoming.text.length)
        : incoming.text.length;
    final baseOffset = selection.isValid
        ? selection.baseOffset.clamp(0, incoming.text.length)
        : cursor;

    final parsed = rawToComposerText(incoming.text);
    final mergedMentions = [..._mentions, ...parsed.mentions];
    final sanitized = cleanupOrphanComposerAtSigns(
      sanitizeBrokenMentionTokens(parsed.text),
      mergedMentions,
      cursor,
    );
    _mentions = pruneMentionsInText(sanitized, mergedMentions);

    final nextCursor = cursor.clamp(0, sanitized.length);
    final nextBase = baseOffset.clamp(0, sanitized.length);

    super.value = TextEditingValue(
      text: sanitized,
      selection: selection.isCollapsed
          ? TextSelection.collapsed(offset: nextCursor)
          : TextSelection(baseOffset: nextBase, extentOffset: nextCursor),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final ranges = getComposerMentionRanges(text, _mentions);
    if (ranges.isEmpty) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final mentionStyle = (style ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
    );
    final children = <TextSpan>[];
    var index = 0;
    for (final range in ranges) {
      if (range.start > index) {
        children.add(TextSpan(text: text.substring(index, range.start)));
      }
      children.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: mentionStyle,
        ),
      );
      index = range.end;
    }
    if (index < text.length) {
      children.add(TextSpan(text: text.substring(index)));
    }
    return TextSpan(style: style, children: children);
  }

  @override
  void clear() {
    _mentions = [];
    super.clear();
  }
}