import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';

/// Matches vcareapp [MessageActionsMenu].
class AvaMessageActionsMenu extends StatelessWidget {
  const AvaMessageActionsMenu({super.key, this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, -4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(LucideIcons.pencil, size: 14),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 14,
                  color: VCareColors.destructive,
                ),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(color: VCareColors.destructive),
                ),
              ],
            ),
          ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 14,
              color: vcare.mutedForeground.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
