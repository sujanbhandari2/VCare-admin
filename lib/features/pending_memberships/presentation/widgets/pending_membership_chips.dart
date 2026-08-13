import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';

/// Pill chip used for membership status and relationship labels.
class PendingMembershipChip extends StatelessWidget {
  const PendingMembershipChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.maxWidth,
  });

  final String label;
  final Color background;
  final Color foreground;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: VCareRadius.fullAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Status chip — parity with web `MembershipStatusBadge` colours.
class PendingMembershipStatusBadge extends StatelessWidget {
  const PendingMembershipStatusBadge({
    super.key,
    required this.status,
    this.maxWidth,
  });

  final MembershipStatus status;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    final (background, foreground) = switch (status) {
      MembershipStatus.submitted => (
        vcare.infoScale.s100,
        vcare.infoScale.s700,
      ),
      MembershipStatus.approved => (
        vcare.successScale.s100,
        vcare.successScale.s700,
      ),
      MembershipStatus.cancelled => (
        vcare.dangerScale.s100,
        vcare.dangerScale.s700,
      ),
      _ => (vcare.muted, vcare.mutedForeground),
    };

    return PendingMembershipChip(
      label: status.label,
      background: background,
      foreground: foreground,
      maxWidth: maxWidth,
    );
  }
}

/// Relationship chip (Primary / Group / dependent labels).
class PendingMembershipRelationshipChip extends StatelessWidget {
  const PendingMembershipRelationshipChip({
    super.key,
    required this.membership,
    this.maxWidth = 170,
  });

  final PendingMembership membership;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final label = membershipRelationshipLabel(membership);
    if (label == null) return const SizedBox.shrink();

    final vcare = context.vcare;
    final (background, foreground) = switch (membershipRelationshipTone(
      membership,
    )) {
      MembershipRelationshipTone.group => (
        vcare.secondaryScale.s100,
        vcare.secondaryScale.s700,
      ),
      MembershipRelationshipTone.primary => (
        vcare.infoScale.s100,
        vcare.infoScale.s700,
      ),
      MembershipRelationshipTone.dependent => (
        vcare.warningScale.s100,
        vcare.warningScale.s700,
      ),
    };

    return PendingMembershipChip(
      label: label,
      background: background,
      foreground: foreground,
      maxWidth: maxWidth,
    );
  }
}
