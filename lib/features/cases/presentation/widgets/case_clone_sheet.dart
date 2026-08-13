import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

/// Confirmation sheet explaining what clone copies / omits.
class CaseCloneSheet extends StatelessWidget {
  const CaseCloneSheet({
    super.key,
    required this.onConfirm,
    this.isLoading = false,
  });

  final VoidCallback onConfirm;
  final bool isLoading;

  static Future<bool?> show(
    BuildContext context, {
    required Future<void> Function() onConfirm,
  }) {
    return context.showBottomSheet<bool>(
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _CaseCloneSheetHost(
        onConfirm: onConfirm,
        sheetContext: sheetContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.vcare.primary.withValues(alpha: 0.1),
                    borderRadius: VCareRadius.lgAll,
                  ),
                  child: Icon(
                    LucideIcons.copy,
                    size: 18,
                    color: context.vcare.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Clone this case?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'A new case will be created with the same type, priority, '
              'client, and assignee. Notes and files are not copied.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: vcare.mutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    text: 'Cancel',
                    onPressed: isLoading ? null : () => context.pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton.elevated(
                    text: 'Clone case',
                    loading: isLoading,
                    onPressed: isLoading ? null : onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseCloneSheetHost extends StatefulWidget {
  const _CaseCloneSheetHost({
    required this.onConfirm,
    required this.sheetContext,
  });

  final Future<void> Function() onConfirm;
  final BuildContext sheetContext;

  @override
  State<_CaseCloneSheetHost> createState() => _CaseCloneSheetHostState();
}

class _CaseCloneSheetHostState extends State<_CaseCloneSheetHost> {
  bool _loading = false;

  Future<void> _handleConfirm() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onConfirm();
      if (widget.sheetContext.mounted) {
        widget.sheetContext.pop(true);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CaseCloneSheet(isLoading: _loading, onConfirm: _handleConfirm);
  }
}
