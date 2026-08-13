import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/account/utils/account_validators.dart';

/// Live password-requirement checklist (web `PASSWORD_REQUIREMENTS`).
class AccountPasswordRequirements extends StatelessWidget {
  const AccountPasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: vcare.muted.withValues(alpha: 0.45),
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: vcare.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: vcare.mutedForeground,
            ),
          ),
          const SizedBox(height: 10),
          for (final requirement in AccountValidators.passwordRequirements) ...[
            _RequirementRow(
              label: requirement.label,
              met: requirement.test(password),
            ),
            if (requirement != AccountValidators.passwordRequirements.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final success = VCareStatusColors.of(context, VCareStatusTone.success);

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: met ? success.background : vcare.card,
            border: Border.all(color: met ? success.border : vcare.border),
          ),
          child: met
              ? Icon(LucideIcons.check, size: 12, color: success.foreground)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: met ? vcare.foreground : vcare.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
