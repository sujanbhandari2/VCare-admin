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

    return Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
  }
}

/// Inline error card for section-level failures.
class VcareInlineErrorCard extends StatelessWidget {
  const VcareInlineErrorCard({
    super.key,
    this.message,
    this.errorType,
    this.onRetry,
    this.retryLabel,
  });

  final String? message;
  final HttpErrorType? errorType;
  final VoidCallback? onRetry;
  final String? retryLabel;

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? context.appLocalization.retry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
