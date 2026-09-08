import 'package:flutter/material.dart';
import 'package:health_messenger_ui/lib/health_messenger_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/network/http_exception.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// Renders chat connection failures with VCare styling instead of raw
/// transport errors such as `Failed host lookup`.
class VcareMessengerConnectionEdgeCase extends StatelessWidget {
  const VcareMessengerConnectionEdgeCase({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MessengerConnectionEdgeCaseView(
      error: error,
      builder: (context, edgeCase) {
        return Center(
          child: SingleChildScrollView(
            child: VcareErrorStatePanel(
              title: _title(edgeCase.type),
              errorType: _errorType(edgeCase.type),
              icon: _icon(edgeCase.type),
              actionLabel: onRetry == null
                  ? null
                  : context.appLocalization.retry,
              onAction: onRetry,
            ),
          ),
        );
      },
    );
  }

  String _title(MessengerConnectionEdgeCaseType type) {
    return switch (type) {
      MessengerConnectionEdgeCaseType.noInternet => 'You are offline',
      MessengerConnectionEdgeCaseType.timeout => 'Connection timed out',
      MessengerConnectionEdgeCaseType.unavailable => 'Chat is unavailable',
    };
  }

  HttpErrorType _errorType(MessengerConnectionEdgeCaseType type) {
    return switch (type) {
      MessengerConnectionEdgeCaseType.noInternet => HttpErrorType.noInternet,
      MessengerConnectionEdgeCaseType.timeout => HttpErrorType.timeout,
      MessengerConnectionEdgeCaseType.unavailable => HttpErrorType.unknown,
    };
  }

  IconData _icon(MessengerConnectionEdgeCaseType type) {
    return switch (type) {
      MessengerConnectionEdgeCaseType.noInternet => LucideIcons.wifiOff,
      MessengerConnectionEdgeCaseType.timeout => LucideIcons.timerOff,
      MessengerConnectionEdgeCaseType.unavailable => LucideIcons.serverCrash,
    };
  }
}
