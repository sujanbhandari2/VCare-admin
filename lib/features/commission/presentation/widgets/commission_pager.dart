import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Previous / Next pager matching the web commission list.
class CommissionPager extends StatelessWidget {
  const CommissionPager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.hasPrev,
    required this.hasNext,
    required this.isBusy,
    required this.onPageChange,
  });

  final int page;
  final int totalPages;
  final bool hasPrev;
  final bool hasNext;
  final bool isBusy;
  final ValueChanged<int> onPageChange;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: !hasPrev || isBusy ? null : () => onPageChange(page - 1),
          icon: const Icon(LucideIcons.chevronLeft, size: 16),
          label: const Text('Previous'),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
          ),
        ),
        Expanded(
          child: Text(
            'Page $page of ${totalPages < 1 ? 1 : totalPages}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: vcare.mutedForeground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        OutlinedButton(
          onPressed: !hasNext || isBusy ? null : () => onPageChange(page + 1),
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            visualDensity: VisualDensity.compact,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Next'),
              SizedBox(width: 4),
              Icon(LucideIcons.chevronRight, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
