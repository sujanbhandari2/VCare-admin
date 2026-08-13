import 'package:flutter/material.dart';

import 'package:vcare_admin/shared/widgets/vcare_keyboard_dismiss_scope.dart';

/// Default outer margin for compact inset sheets (image picker, pickers, etc.).
EdgeInsets vcareCompactBottomSheetMargin(BuildContext context) {
  return EdgeInsets.fromLTRB(
    16,
    0,
    16,
    MediaQuery.paddingOf(context).bottom + 16,
  );
}

/// Shared floating-card chrome for modal bottom sheets.
///
/// Renders an elevated card above the scrim with optional drag handle.
/// Used by [BuildContextExt.showBottomSheet] so feature sheets only provide
/// content. The extension positions this card at the screen bottom.
class VcareFloatingBottomSheetCard extends StatelessWidget {
  const VcareFloatingBottomSheetCard({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.9,
    this.margin = EdgeInsets.zero,
    this.topRadius = 24,
    this.showDragHandle = true,
  });

  final Widget child;
  final double maxHeightFactor;
  final EdgeInsetsGeometry margin;
  final double topRadius;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom;
    final maxHeight = (availableHeight * maxHeightFactor).clamp(
      0.0,
      availableHeight,
    );

    return Padding(
      padding: margin,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(topRadius),
            ),
            side: BorderSide(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
              Flexible(child: VcareKeyboardDismissScope(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
