import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/account/utils/account_formatters.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/user_profile_avatar.dart';

/// Profile header: avatar, name, email, and tenant/role/status badges.
class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({super.key, required this.user});

  final AuthMeUser user;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final name = AccountFormatters.displayName(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
    );
    final email = user.email?.trim() ?? '';
    final tenant = user.currentTenant?.name?.trim() ?? '';
    final role = user.currentRoles.isNotEmpty ? user.currentRoles.first : null;
    final status = user.status?.trim() ?? '';
    final isActive = status.toUpperCase() == 'ACTIVE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: VCareRadius.xxlAll,
        border: Border.all(color: vcare.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            vcare.card,
            Color.lerp(vcare.card, vcare.primary.withValues(alpha: 0.08), 1)!,
          ],
        ),
      ),
      child: Column(
        children: [
          UserProfileAvatar(
            name: name,
            size: 72,
            circular: true,
            initialsFontSize: 24,
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: vcare.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (tenant.isNotEmpty)
                _AccountBadge(
                  label: tenant,
                  tone: VCareStatusTone.primary,
                ),
              if (role != null && role.trim().isNotEmpty)
                _AccountBadge(
                  label: AccountFormatters.formatRoleLabel(role),
                  tone: VCareStatusTone.neutral,
                ),
              if (status.isNotEmpty)
                _AccountBadge(
                  label: AccountFormatters.formatRoleLabel(status),
                  tone: isActive
                      ? VCareStatusTone.success
                      : VCareStatusTone.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountBadge extends StatelessWidget {
  const _AccountBadge({required this.label, required this.tone});

  final String label;
  final VCareStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = VCareStatusColors.of(context, tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }
}
