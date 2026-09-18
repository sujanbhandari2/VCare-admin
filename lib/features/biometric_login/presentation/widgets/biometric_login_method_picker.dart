import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';

enum BiometricLoginMethod {
  face,
  fingerprint,
}

extension BiometricLoginMethodX on BiometricLoginMethod {
  String get label => switch (this) {
        BiometricLoginMethod.face => 'Face ID',
        BiometricLoginMethod.fingerprint => 'Fingerprint',
      };

  String get reason => switch (this) {
        BiometricLoginMethod.face => 'Confirm with Face ID to sign in.',
        BiometricLoginMethod.fingerprint =>
          'Confirm with fingerprint to sign in.',
      };

  /// Native channel preference: `face`, `fingerprint`, or `any`.
  String get nativePreference => switch (this) {
        BiometricLoginMethod.face => 'face',
        BiometricLoginMethod.fingerprint => 'fingerprint',
      };
}

/// Returns the available biometric methods on this device.
Future<List<BiometricLoginMethod>> availableBiometricLoginMethods() async {
  try {
    final localAuth = LocalAuthentication();
    if (!await localAuth.canCheckBiometrics) {
      return const [];
    }

    final available = await localAuth.getAvailableBiometrics();
    final methods = <BiometricLoginMethod>[];

    if (available.contains(BiometricType.face)) {
      methods.add(BiometricLoginMethod.face);
    }
    if (available.contains(BiometricType.fingerprint)) {
      methods.add(BiometricLoginMethod.fingerprint);
    }

    // Some Android devices only report strong/weak without a specific type.
    if (methods.isEmpty &&
        (available.contains(BiometricType.strong) ||
            available.contains(BiometricType.weak))) {
      methods.add(BiometricLoginMethod.fingerprint);
    }

    return methods;
  } catch (_) {
    return const [];
  }
}

/// Lets the user pick Face ID or Fingerprint when both are available.
///
/// Returns the selected method, or `null` if cancelled. When only one method
/// is available, returns it without showing a sheet.
Future<BiometricLoginMethod?> resolveBiometricLoginMethod(
  BuildContext context,
) async {
  final methods = await availableBiometricLoginMethods();
  if (methods.isEmpty) {
    return BiometricLoginMethod.fingerprint;
  }
  if (methods.length == 1) {
    return methods.first;
  }
  if (!context.mounted) {
    return null;
  }

  return showModalBottomSheet<BiometricLoginMethod>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose biometric',
                textAlign: TextAlign.center,
                style: sheetContext.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use Face ID or fingerprint to sign in.',
                textAlign: TextAlign.center,
                style: sheetContext.textTheme.bodyMedium?.copyWith(
                  color: sheetContext.theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),
              if (methods.contains(BiometricLoginMethod.face)) ...[
                _BiometricMethodTile(
                  icon: Icons.face_rounded,
                  label: 'Face ID',
                  onTap: () => Navigator.of(sheetContext).pop(
                    BiometricLoginMethod.face,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (methods.contains(BiometricLoginMethod.fingerprint))
                _BiometricMethodTile(
                  icon: LucideIcons.fingerprint,
                  label: 'Fingerprint',
                  onTap: () => Navigator.of(sheetContext).pop(
                    BiometricLoginMethod.fingerprint,
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BiometricMethodTile extends StatelessWidget {
  const _BiometricMethodTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
