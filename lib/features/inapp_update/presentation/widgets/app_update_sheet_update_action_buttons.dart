import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../shared/utils/extension_functions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/remote_config_app_update_info.dart';

class AppUpdateSheetUpdateActionButtons extends StatelessWidget {
  const AppUpdateSheetUpdateActionButtons({super.key, required this.info});

  final RemoteConfigAppUpdateInfo info;

  Future<void> _launchStore() async {
    try {
      final storeUrl = Platform.isIOS
          ? 'https://apps.apple.com/app/myswaddle/id1585637439'
          : 'https://play.google.com/store/apps/details?id=com.novelty.medicaid';
      if (await canLaunchUrlString(storeUrl)) {
        await launchUrlString(storeUrl);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 42),
      child: Row(
        children: [
          if (!info.isForceUpdate) ...[
            Expanded(
              child: AppButton.outlined(
                padding: .zero,
                onPressed: context.pop,
                text: context.appLocalization.update_later,
                color: context.isDarkTheme ? Colors.white70 : Colors.black54,
                onButtonColor: context.isDarkTheme ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: AppButton.elevated(
              onPressed: _launchStore,
              text: context.appLocalization.update_now,
            ),
          ),
        ],
      ),
    );
  }
}
