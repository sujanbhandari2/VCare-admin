import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';

/// Client banner at the top of the review sheet — parity with web
/// `ApprovalClientProfileHeader` (avatar, identity, meta chips).
class PendingMembershipClientHeader extends StatelessWidget {
  const PendingMembershipClientHeader({
    super.key,
    required this.client,
    this.trailing,
  });

  final MembershipClient client;
  final Widget? trailing;

  static const double _avatarSize = 72;
  static const double _avatarRing = 3;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final address = client.formattedAddress;
    final identityNote = client.ssnLast4?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: vcare.card,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_avatarRing),
                  child: ProfileAvatar(
                    name: client.displayName,
                    photoUrl: client.avatarUrl,
                    size: _avatarSize,
                    circular: true,
                    initialsFontSize: 24,
                    initialsFontWeight: FontWeight.w600,
                    initialsColor: vcare.primary,
                    backgroundColor: vcare.primaryScale.s100,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (client.email?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          client.email!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: LucideIcons.cake,
                label: formatMembershipDateString(client.dateOfBirth),
              ),
              _MetaChip(
                icon: LucideIcons.smartphone,
                label: formatMembershipPhone(client.phone),
              ),
              if (identityNote != null && identityNote.isNotEmpty)
                _MetaChip(icon: LucideIcons.creditCard, label: identityNote),
              _MetaChip(
                icon: LucideIcons.mapPin,
                label: address.isEmpty ? membershipEmptyValue : address,
                maxWidth: 220,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.maxWidth});

  final IconData icon;
  final String label;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: vcare.mutedForeground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
