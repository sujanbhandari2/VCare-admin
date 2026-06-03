import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/core/styles/app_theme.dart';

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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      useRootNavigator: true,
      isScrollControlled: false,
      enableDrag: false,
      isDismissible: dismissible,
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
    return Padding(
      padding: .only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: context.padding.bottom + 16.0,
      ),
      child: Material(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: .circular(24.0),
        clipBehavior: .antiAlias,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Align(
              alignment: .topRight,
              child: Padding(
                padding: const .only(top: 24.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    // Icon(Icons.error_outline_outlined, color: AppColors.red,),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context
                                .appLocalization
                                .location_service_dialog_title,
                            style: context.textTheme.semibold16?.copyWith(
                              fontWeight: .bold,
                            ),
                            textAlign: .center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const .all(16.0),
              child: Text(
                context.appLocalization.location_service_dialog_body,
                style: context.textTheme.regular14?.copyWith(height: 1.75),
                textScaler: TextScaler.linear(0.95),
              ),
            ),
            Padding(
              padding: .only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: Platform.isIOS ? 24.0 : 8.0,
              ),
              child: AppButton.elevated(
                text: Platform.isIOS
                    ? context.appLocalization.continue_
                    : context.appLocalization.allow,
                padding: .zero,
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
                padding: const .only(left: 16.0, right: 16.0, bottom: 16.0),
                child: AppButton.text(
                  text: context.appLocalization.cancel,
                  padding: .zero,
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
        ),
      ),
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
