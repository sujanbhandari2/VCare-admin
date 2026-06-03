import 'package:flutter/material.dart';

import '../../../../shared/utils/extension_functions.dart';
import '../../domain/entities/remote_config_app_update_info.dart';

class AppUpdateSheetAppInfoRow extends StatelessWidget {
  const AppUpdateSheetAppInfoRow({super.key, required this.info});

  final RemoteConfigAppUpdateInfo info;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: context.theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/branding/logo-without-text.png',
              width: 32,
              height: 32,
              errorBuilder: (_, _, _) => SizedBox.shrink(),
            ),
          ),
        ),

        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(context.appLocalization.app_name, style: context.textTheme.titleMedium),
              Text(
                'v${info.latestVersion ?? 'Unknown'}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
