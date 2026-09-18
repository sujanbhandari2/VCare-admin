import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/network_error_message.dart';

/// Shared empty/error panel used for fetch failures and other edge states.
class VcareErrorStatePanel extends StatelessWidget {
  const VcareErrorStatePanel({
    super.key,
    required this.title,
    this.message,
    this.errorType,
    this.icon = LucideIcons.wifiOff,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.all(32),
  });

  final String title;
  final String? message;
  final HttpErrorType? errorType;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final subtitle = NetworkErrorMessage.displayMessage(
      context,
      message: message,
      errorType: errorType,
    );

    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: context.vcare.mutedForeground),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.vcare.mutedForeground),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );

    // Center within whatever space the parent provides (e.g. SliverFillRemaining,
    // Expanded, or a full Scaffold body). Falls back to intrinsic size in lists.
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight =
            constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        if (!hasBoundedHeight) {
          return content;
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Center(child: SingleChildScrollView(child: content)),
        );
      },
    );
  }
}

/// Inline error card for section-level failures.
///
/// Always sanitizes [message] through [NetworkErrorMessage] so raw HTML,
/// proxy pages, and stack traces never appear in the UI.
class VcareInlineErrorCard extends StatelessWidget {
  const VcareInlineErrorCard({
    super.key,
    this.message,
    this.errorType,
    this.title,
    this.icon = LucideIcons.wifiOff,
    this.onRetry,
    this.retryLabel,
    this.compact = false,
  });

  final String? message;
  final HttpErrorType? errorType;
  final String? title;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  /// When true, omits the icon for dense list/footer placements.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final displayMessage = NetworkErrorMessage.displayMessage(
      context,
      message: message,
      errorType: errorType,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!compact) ...[
            Icon(icon, size: 28, color: vcare.mutedForeground),
            const SizedBox(height: 10),
          ],
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: vcare.foreground,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            maxLines: compact ? 3 : 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? context.appLocalization.retry),
            ),
          ],
        ],
      ),
    );
  }
}
