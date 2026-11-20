import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/shared/network/connectivity_status_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// Full-page offline edge state used when a screen has no content to show.
class VcareOfflineErrorPanel extends StatelessWidget {
  const VcareOfflineErrorPanel({
    super.key,
    this.title = 'You are offline',
    this.onRetry,
    this.padding = const EdgeInsets.all(32),
  });

  final String title;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return VcareErrorStatePanel(
      title: title,
      errorType: HttpErrorType.noInternet,
      icon: LucideIcons.wifiOff,
      actionLabel: onRetry == null ? null : context.appLocalization.retry,
      onAction: onRetry,
      padding: padding,
    );
  }
}

/// Compact offline banner for pages that still have stale content.
class VcareOfflineBanner extends ConsumerWidget {
  const VcareOfflineBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isNetworkOnlineProvider);
    if (online) return const SizedBox.shrink();

    return Material(
      color: context.theme.colorScheme.errorContainer.withValues(alpha: 0.9),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 16,
                color: context.theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.appLocalization.no_internet_connection,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: context.theme.colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(context.appLocalization.retry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
