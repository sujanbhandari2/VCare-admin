import 'package:flutter/material.dart';

import '../../../../shared/utils/extension_functions.dart';
import '../../domain/entities/remote_config_app_update_info.dart';
import 'app_update_sheet_app_info_row.dart';
import 'app_update_sheet_release_notes_tile.dart';
import 'app_update_sheet_update_action_buttons.dart';

class AppUpdateSheet extends StatelessWidget {
  const AppUpdateSheet._({required this.info});

  final RemoteConfigAppUpdateInfo info;

  static bool _isAlreadyShowing = false;

  static Future<T?> show<T>(
    BuildContext context, {
    required RemoteConfigAppUpdateInfo info,
  }) {
    if (_isAlreadyShowing) return Future.value(null);

    _isAlreadyShowing = true;

    return showModalBottomSheet<T>(
      context: context,
      barrierColor: context.isDarkTheme ? Colors.white12 : Colors.black26,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AppUpdateSheet._(info: info),
    ).whenComplete(() => _isAlreadyShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.appLocalization.update_available,
                  style: context.textTheme.titleLarge,
                  textScaler: const TextScaler.linear(0.85),
                ),
                const SizedBox(height: 12),
                Text(
                  context.appLocalization.update_available_desc,
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppUpdateSheetAppInfoRow(info: info),
                const SizedBox(height: 24),
                Flexible(
                  child: AppUpdateSheetReleaseNotesTile(info: info),
                ),
                AppUpdateSheetUpdateActionButtons(info: info),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
