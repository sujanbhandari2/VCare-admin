import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/account/utils/account_formatters.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';

/// Read-only account metadata section.
class AccountDetailsSection extends StatelessWidget {
  const AccountDetailsSection({super.key, required this.user});

  final AuthMeUser user;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: VCareRadius.xxlAll,
        side: BorderSide(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vcare.mutedForeground,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Member since',
              value: AccountFormatters.formatAccountDate(user.createdAt),
            ),
            Divider(height: 1, color: vcare.border),
            _DetailRow(
              label: 'Email verified',
              value: AccountFormatters.emailVerifiedLabel(user.emailVerifiedAt),
            ),
            Divider(height: 1, color: vcare.border),
            _DetailRow(
              label: 'Account type',
              value: AccountFormatters.formatRoleLabel(user.userType),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: vcare.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
