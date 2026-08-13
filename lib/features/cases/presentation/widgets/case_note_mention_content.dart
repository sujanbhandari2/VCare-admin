import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/utils/case_utils.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Label shown for a mention of somebody without access to the case.
const String caseNoteExternalMentionLabel = 'External — no case access';

/// Renders note content with bold mentions, tag pills, and clone links.
class CaseNoteMentionContent extends StatelessWidget {
  const CaseNoteMentionContent({
    super.key,
    required this.content,
    this.tags = const [],
  });

  final String content;
  final List<CaseNoteTag> tags;

  bool _isExternalMention(String email) {
    if (tags.isEmpty) return false;
    for (final tag in tags) {
      if (tag.taggedEmail.toLowerCase() == email.toLowerCase()) {
        return tag.taggedUserId == null;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    final vcare = context.vcare;
    final baseStyle = TextStyle(
      fontSize: 13,
      height: 1.6,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final clonedFrom = parseClonedFromCaseNote(content);
    if (clonedFrom != null) {
      return Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: '${capitalizeWords(clonedFrom.labelPrefix)} '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => context.pushNamed(
                  AppRouter.caseDetailName,
                  pathParameters: {'id': clonedFrom.caseId},
                ),
                child: Text(
                  clonedFrom.caseId,
                  style: baseStyle.copyWith(
                    color: context.vcare.primary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: context.vcare.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final segments = parseNoteMentionSegments(content);
    final hasMentions = segments.any((segment) => segment.isMention);

    // Legacy notes store plain text plus a separate tag list.
    if (!hasMentions && tags.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(capitalizeWords(content), style: baseStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tag in tags)
                _TagPill(
                  label: '@${tag.taggedName.isEmpty ? tag.taggedEmail : tag.taggedName}',
                  isExternal: tag.taggedUserId == null,
                ),
            ],
          ),
        ],
      );
    }

    final mentionStyle = baseStyle.copyWith(fontWeight: FontWeight.w600);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (final segment in segments)
            if (!segment.isMention)
              TextSpan(text: capitalizeWords(segment.value))
            else if (_isExternalMention(segment.email!))
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Tooltip(
                  message: caseNoteExternalMentionLabel,
                  child: Text(
                    capitalizeWords(segment.name!),
                    style: mentionStyle.copyWith(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                      decorationColor: vcare.mutedForeground,
                    ),
                  ),
                ),
              )
            else
              TextSpan(
                text: capitalizeWords(segment.name!),
                style: mentionStyle,
              ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.isExternal});

  final String label;
  final bool isExternal;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.muted,
        borderRadius: VCareRadius.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, color: vcare.mutedForeground),
        ),
      ),
    );

    if (!isExternal) return pill;

    return Tooltip(message: caseNoteExternalMentionLabel, child: pill);
  }
}
