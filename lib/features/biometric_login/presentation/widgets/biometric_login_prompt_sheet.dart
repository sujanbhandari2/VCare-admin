import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

Future<bool?> showBiometricPromptSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String primaryLabel,
  String secondaryLabel = 'Skip for now',
  String biometricLabel = 'Biometric',
  Future<void> Function()? onPrimaryPressed,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon,
                  size: 34,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            if (_processing) ...[
              LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 12),
              Text(
                _processingLabel,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),
            ],
            AppButton.elevated(
              text: widget.primaryLabel,
              icon: _icon,
              loading: _processing,
              onPressed: _handlePrimaryPressed,
            ),
            const SizedBox(height: 10),
            AppButton.text(
              text: widget.secondaryLabel,
              onPressed: _processing ? null : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
