import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/shared/widgets/vcare_floating_bottom_sheet.dart';

class LocationPermissionRequestBottomSheet extends StatefulWidget {
  final VoidCallback? onAllowClick;
  final VoidCallback? onCancelClick;

  const LocationPermissionRequestBottomSheet({
    super.key,
    this.onAllowClick,
    this.onCancelClick,
  });

  /// Method to show bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    VoidCallback? onAllowClick,
    VoidCallback? onCancelClick,
    bool dismissible = false,
  }) {
    return context.showBottomSheet<T>(
      builder: (BuildContext context) {
        return LocationPermissionRequestBottomSheet(
          onAllowClick: onAllowClick,
          onCancelClick: onCancelClick,
        );
      },
      enableDrag: false,
      isDismissible: dismissible,
      margin: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      topRadius: 24,
    );
  }

  @override
  State<LocationPermissionRequestBottomSheet> createState() =>
      _LocationPermissionRequestBottomSheetState();
}

class _LocationPermissionRequestBottomSheetState
    extends State<LocationPermissionRequestBottomSheet> {
  // Flag to handle the dismissed by back button
  bool _isAlreadyDismissed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.appLocalization.location_service_dialog_title,
                        style: context.textTheme.semibold16?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            context.appLocalization.location_service_dialog_body,
            style: context.textTheme.regular14?.copyWith(height: 1.75),
            textScaler: const TextScaler.linear(0.95),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: Platform.isIOS ? 24.0 : 8.0,
          ),
          child: AppButton.elevated(
            text: Platform.isIOS
                ? context.appLocalization.continue_
                : context.appLocalization.allow,
            padding: EdgeInsets.zero,
            height: 46.0,
            onPressed: () {
              _isAlreadyDismissed = true;

              context.pop();
              Future.delayed(const Duration(milliseconds: 375), () {
                widget.onAllowClick?.call();
              });
            },
          ),
        ),
        if (!Platform.isIOS)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: AppButton.text(
              text: context.appLocalization.cancel,
              padding: EdgeInsets.zero,
              height: 46.0,
              onPressed: () {
                _isAlreadyDismissed = true;

                context.pop();
                Future.delayed(const Duration(milliseconds: 375), () {
                  widget.onCancelClick?.call();
                });
              },
            ),
          ),
      ],
    );
  }

  @override
  void deactivate() {
    if (!_isAlreadyDismissed) {
      widget.onCancelClick?.call();
    }
    super.deactivate();
  }
}
