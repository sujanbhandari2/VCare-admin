import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class BiometricLoginStatusTile extends StatelessWidget {
  const BiometricLoginStatusTile({
    super.key,
    required this.status,
    required this.onTap,
    this.loading = false,
  });

  final BiometricLoginStatus status;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isActive = status.isEnrolled;
    final primaryText = isActive ? 'Active' : 'Inactive';
    final secondaryText = isActive
        ? [
            status.displayType,
            if ((status.deviceName ?? '').trim().isNotEmpty)
              status.deviceName!.trim(),
          ].join(' · ')
        : 'Tap to enable biometric sign-in.';

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.theme.colorScheme.primaryContainer,
              child: Icon(
                LucideIcons.fingerprint,
                size: 18,
                color: context.theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$primaryText · $secondaryText',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.theme.hintColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isActive ? LucideIcons.chevronRight : LucideIcons.plus,
                size: 18,
                color: context.theme.hintColor,
              ),
          ],
        ),
      ),
    );
  }
}
