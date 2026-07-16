import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

Future<void> showVcareSuccessDrawer({
  required BuildContext context,
  required String title,
  String? description,
  String actionLabel = 'Done',
  VoidCallback? onAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: VCareColors.background,
    barrierColor: Colors.black.withValues(alpha: 0.2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _VcareSuccessDrawer(
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}

class _VcareSuccessDrawer extends StatelessWidget {
  const _VcareSuccessDrawer({
    required this.title,
    this.description,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: vcare.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: VCareColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                size: 32,
                color: VCareColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: vcare.mutedForeground,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAction?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: VCareColors.primary,
                  foregroundColor: VCareColors.primaryForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
