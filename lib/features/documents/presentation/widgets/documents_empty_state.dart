import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

class DocumentsEmptyState extends StatelessWidget {
  const DocumentsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 32,
              color: vcare.mutedForeground,
            ),
            const SizedBox(height: 8),
            const Text(
              'No documents yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Photos, voice notes, and files you attach to requests or your ID card will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: vcare.mutedForeground,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
