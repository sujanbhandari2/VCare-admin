import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/ava/data/ava_mock_data.dart';
import 'package:vcare_admin/features/ava/presentation/widgets/ava_layout.dart';

/// Matches vcareapp [AvaSuggestionList].
class AvaSuggestionList extends StatelessWidget {
  const AvaSuggestionList({super.key, required this.onSelect});

  final void Function(String text) onSelect;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Try asking'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: vcare.mutedForeground,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < AvaMockData.suggestions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _SuggestionChip(
              label: AvaMockData.suggestions[i],
              onTap: () => onSelect(AvaMockData.suggestions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AvaLayout.bubbleRadius),
        side: BorderSide(color: vcare.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AvaLayout.bubbleRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(fontSize: AvaLayout.bubbleFontSize),
            ),
          ),
        ),
      ),
    );
  }
}
