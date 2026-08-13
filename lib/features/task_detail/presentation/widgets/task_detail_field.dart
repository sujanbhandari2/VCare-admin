import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Field row for the task sheet: an uppercase label above a bordered value box.
///
/// Without [onTap] it renders the disabled look of the web drawer's view mode;
/// with [onTap] it becomes the edit form's picker control.
class TaskDetailField extends StatelessWidget {
  const TaskDetailField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.dotColor,
    this.maxLines = 1,
    this.isPlaceholder = false,
    this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? dotColor;
  final int maxLines;

  /// Renders the value muted, for stand-ins like "Unassigned" or "Not set".
  final bool isPlaceholder;

  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: onClear != null ? 4 : 12,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: isPlaceholder ? vcare.mutedForeground : vcare.foreground,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(LucideIcons.x, size: 14),
                color: vcare.mutedForeground,
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear',
              ),
            if (onTap != null)
              Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: vcare.mutedForeground,
              ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: vcare.mutedForeground),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: vcare.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (onTap == null)
          box
        else
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: VCareRadius.lgAll,
              child: box,
            ),
          ),
      ],
    );
  }
}
