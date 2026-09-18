import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

Future<bool?> showBiometricPromptSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String primaryLabel,
  String secondaryLabel = 'Maybe later',
  String biometricLabel = 'Biometric',
  Future<void> Function()? onPrimaryPressed,
}) {
  return context.showBottomSheet<bool>(
    isScrollControlled: true,
    builder: (sheetContext) {
      return _BiometricPromptSheetBody(
        title: title,
        description: description,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        biometricLabel: biometricLabel,
        onPrimaryPressed: onPrimaryPressed,
      );
    },
  );
}

class _BiometricPromptSheetBody extends StatefulWidget {
  const _BiometricPromptSheetBody({
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.biometricLabel,
    this.onPrimaryPressed,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final String secondaryLabel;
  final String biometricLabel;
  final Future<void> Function()? onPrimaryPressed;

  @override
  State<_BiometricPromptSheetBody> createState() =>
      _BiometricPromptSheetBodyState();
}

class _BiometricPromptSheetBodyState extends State<_BiometricPromptSheetBody> {
  bool _processing = false;

  Future<void> _handlePrimaryPressed() async {
    if (_processing) {
      return;
    }

    if (widget.onPrimaryPressed == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await widget.onPrimaryPressed!.call();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  IconData get _icon {
    final label = widget.biometricLabel.trim().toLowerCase();
    if (label.contains('face')) {
      return Icons.face_rounded;
    }
    return LucideIcons.fingerprint;
  }

  String get _processingLabel {
    final label = widget.biometricLabel.trim();
    if (label.contains('Face')) {
      return 'Aligning your face…';
    }
    if (label.contains('Fingerprint')) {
      return 'Waiting for fingerprint…';
    }
    return 'Processing biometric…';
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final textTheme = context.textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: vcare.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon,
                  size: 34,
                  color: vcare.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: vcare.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: vcare.mutedForeground,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (_processing) ...[
              LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(999),
                color: vcare.primary,
                backgroundColor: vcare.primary.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 12),
              Text(
                _processingLabel,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: vcare.mutedForeground,
                ),
              ),
              const SizedBox(height: 20),
            ],
            AppButton.elevated(
              text: widget.primaryLabel,
              icon: _icon,
              loading: _processing,
              height: 48,
              onPressed: _handlePrimaryPressed,
            ),
            const SizedBox(height: 8),
            AppButton.text(
              text: widget.secondaryLabel,
              height: 44,
              onPressed: _processing ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
