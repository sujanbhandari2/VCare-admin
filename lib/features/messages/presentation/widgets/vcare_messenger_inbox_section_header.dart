import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Section title for the combined Live Chat inbox (Chats / People).
class VcareMessengerInboxSectionHeader extends StatelessWidget {
  const VcareMessengerInboxSectionHeader({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: vcare.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
