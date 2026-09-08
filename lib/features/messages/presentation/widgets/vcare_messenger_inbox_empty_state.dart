import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Inline empty state when Live Chat has no conversations and no available people.
class VcareMessengerInboxEmptyState extends StatelessWidget {
  const VcareMessengerInboxEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: VCareColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              LucideIcons.messageCircle,
              color: VCareColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No conversations and people right now',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or check back later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: vcare.mutedForeground,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
