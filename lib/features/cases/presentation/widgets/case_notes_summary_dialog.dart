import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Dialog showing the AI-generated notes summary.
///
/// Parity with web `CaseNotesSummaryDialog`.
class CaseNotesSummaryDialog extends StatelessWidget {
  const CaseNotesSummaryDialog({
    super.key,
    required this.summaryText,
  });

  final String summaryText;

  static Future<void> show(
    BuildContext context, {
    required String summaryText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => CaseNotesSummaryDialog(
        summaryText: summaryText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.sparkles, size: 16, color: context.vcare.primary),
          const SizedBox(width: 8),
          const Text('AI Notes Summary'),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          summaryText,
          style: const TextStyle(fontSize: 13, height: 1.6),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
