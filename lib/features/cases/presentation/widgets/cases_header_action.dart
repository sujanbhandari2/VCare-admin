import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Header CTA for creating a new advocacy case.
class CasesHeaderAction extends StatelessWidget {
  const CasesHeaderAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.vcare.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plus, size: 16, color: context.vcare.primary),
          const SizedBox(width: 6),
          Text(
            'New case',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.vcare.primary,
            ),
          ),
        ],
      ),
    );
  }
}
