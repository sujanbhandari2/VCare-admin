import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_theme.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.seeAllLabel,
    this.onSeeAll,
    this.showPreviewToggle = false,
    this.previewEmpty = false,
    this.onPreviewToggle,
  });

  final String title;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final bool showPreviewToggle;
  final bool previewEmpty;
  final VoidCallback? onPreviewToggle;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (showPreviewToggle && kDebugMode)
            _PreviewToggle(
              previewEmpty: previewEmpty,
              onToggle: onPreviewToggle,
              muted: vcare.muted,
              mutedForeground: vcare.mutedForeground,
            ),
          if (seeAllLabel != null && onSeeAll != null) ...[
            if (showPreviewToggle && kDebugMode) const SizedBox(width: 8),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                seeAllLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle({
    required this.previewEmpty,
    required this.onToggle,
    required this.muted,
    required this.mutedForeground,
  });

  final bool previewEmpty;
  final VoidCallback? onToggle;
  final Color muted;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: muted,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onToggle,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            previewEmpty ? LucideIcons.eye : LucideIcons.eyeOff,
            size: 12,
            color: mutedForeground,
          ),
        ),
      ),
    );
  }
}
