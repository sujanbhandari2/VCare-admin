import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_current_location_state_provider.dart';
import 'package:vcare_admin/features/find_care/presentation/providers/find_care_search_location_provider.dart';
import 'package:vcare_admin/shared/widgets/location_permission_request_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Orchestrates permission explanation + device location detection for Find Care.
///
/// - User-initiated (locate button): may re-show the explanation sheet after denial.
/// - Automatic mode ([userInitiated] false) still prompts at most once per session
///   if called, but Find Care no longer auto-prompts on open.
Future<void> runFindCareCurrentLocationFlow(
  BuildContext context,
  WidgetRef ref, {
  required bool userInitiated,
  bool showSuccessToast = true,
}) async {
  final notifier = ref.read(findCareCurrentLocationStateProvider.notifier);
  final currentState = ref.read(findCareCurrentLocationStateProvider);

  if (currentState.detecting) return;

  if (!userInitiated && currentState.autoPromptCompleted) {
    return;
  }

  // Mark before any await so concurrent rebuilds cannot double-prompt.
  if (!userInitiated) {
    notifier.markAutoPromptCompleted();
  }

  final hasPermission = await notifier.hasPermission();
  if (!context.mounted) return;

  if (!hasPermission) {
    final allowed = await _requestPermissionViaExplanationSheet(context);
    if (!allowed || !context.mounted) return;
  }

  final result = await notifier.detectCurrentLocation(requestPermission: true);
  if (!context.mounted) return;

  _showLocationResultToast(
    context,
    ref,
    result: result,
    showSuccessToast: showSuccessToast,
  );
}

Future<bool> _requestPermissionViaExplanationSheet(BuildContext context) async {
  final completer = Completer<bool>();

  // The sheet pops before invoking Allow/Cancel (delayed ~375ms). Wait on the
  // callback completer instead of the modal future so Allow is not treated as
  // a cancel.
  unawaited(
    LocationPermissionRequestBottomSheet.show<void>(
      context,
      onAllowClick: () {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onCancelClick: () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
    }),
  );

  return completer.future;
}

void _showLocationResultToast(
  BuildContext context,
  WidgetRef ref, {
  required CurrentLocationResult result,
  required bool showSuccessToast,
}) {
  switch (result) {
    case CurrentLocationSuccess(:final location):
      if (!showSuccessToast) return;
      final label = location.displayLabel.isNotEmpty
          ? location.displayLabel
          : ref.read(findCareSearchLocationProvider).displayLabel;
      context.showVcareToast(
        title: 'Search area updated',
        description: label,
        variant: VcareToastVariant.info,
      );
    case CurrentLocationFailure(:final userMessage, :final reason):
      // Silent for the automatic prompt when the user simply declines.
      if (!showSuccessToast &&
          reason == CurrentLocationFailureReason.permissionDenied) {
        return;
      }
      if (reason == CurrentLocationFailureReason.serviceDisabled ||
          reason == CurrentLocationFailureReason.permissionDeniedForever) {
        unawaited(_showLocationSettingsDialog(context, reason));
        return;
      }
      context.showVcareToast(
        title: 'Location unavailable',
        description: userMessage,
        variant:
            reason == CurrentLocationFailureReason.permissionDenied ||
                reason == CurrentLocationFailureReason.permissionDeniedForever
            ? VcareToastVariant.warning
            : VcareToastVariant.destructive,
      );
  }
}

Future<void> _showLocationSettingsDialog(
  BuildContext context,
  CurrentLocationFailureReason reason,
) async {
  final isServiceDisabled =
      reason == CurrentLocationFailureReason.serviceDisabled;
  final openSettings = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          isServiceDisabled
              ? 'Turn on location services'
              : 'Allow location access',
        ),
        content: Text(
          isServiceDisabled
              ? 'Location services are turned off. Turn them on in Settings '
                    'to find providers near you.'
              : 'Location access is blocked for this app. Enable it in '
                    'Settings to find providers near you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      );
    },
  );

  if (openSettings != true || !context.mounted) return;

  await AppSettings.openAppSettings(
    type: isServiceDisabled
        ? AppSettingsType.location
        : AppSettingsType.settings,
  );
}
