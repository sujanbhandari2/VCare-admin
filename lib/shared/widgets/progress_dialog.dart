import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_template/shared/widgets/shimmer.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

class ProgressDialog extends StatelessWidget {
  final String? label;
  final bool shimmer;

  const ProgressDialog({super.key, this.label, this.shimmer = false});

  /// Method to show bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    String? label,
    bool shimmer = false,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      useRootNavigator: true,
      barrierColor: context.theme.dividerColor.withValues(alpha: 0.10),
      builder: (_) {
        return ProgressDialog(label: label, shimmer: shimmer);
      },
    );
  }

  /// Method to hide bottom sheet
  ///
  static Future<void> hide<T>(BuildContext context, [T? result]) async {
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: shimmer
            ? Shimmer(
                loading: true,
                child: Shimmer.loadingContainer(
                  context,
                  width: context.width,
                  height: context.height,
                  opacity: 0.075,
                  radius: 0.0,
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: .min,
                  spacing: 8.0,
                  children: [
                    CircularProgressIndicator(strokeWidth: 3.0),
                    if (label != null && label!.isNotEmpty)
                      Text(
                        label!,
                        style: context.textTheme.bodyMedium,
                        textAlign: .center,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
