import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_chips.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';

/// Associated / relevant membership list inside the review sheet — parity with
/// web `DrawerMembershipSectionTable`, rendered as stacked rows for mobile.
class PendingMembershipSection extends StatelessWidget {
  const PendingMembershipSection({
    super.key,
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.memberships,
    this.loading = false,
    this.hasError = false,
    this.onRetry,
    this.showClientName = false,
    this.hasMore = false,
    this.remainingCount = 0,
    this.loadingMore = false,
    this.onLoadMore,
  });

  final String title;
  final String description;
  final String emptyMessage;
  final IconData emptyIcon;
  final List<PendingMembership> memberships;
  final bool loading;
  final bool hasError;
  final VoidCallback? onRetry;
  final bool showClientName;
  final bool hasMore;
  final int remainingCount;
  final bool loadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: vcare.mutedForeground,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (loading)
          _SectionShell(
            child: Text(
              'Loading memberships…',
              style: TextStyle(fontSize: 13, color: vcare.mutedForeground),
            ),
          )
        else if (hasError)
          VcareInlineErrorCard(
            title: 'Could not load memberships',
            onRetry: onRetry,
            compact: true,
          )
        else if (memberships.isEmpty)
          _SectionEmpty(icon: emptyIcon, message: emptyMessage)
        else ...[
          for (var i = 0; i < memberships.length; i++) ...[
            _SectionRow(
              membership: memberships[i],
              showClientName: showClientName,
            ),
            if (i < memberships.length - 1) const SizedBox(height: 8),
          ],
          if (hasMore && onLoadMore != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: loadingMore ? null : onLoadMore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  loadingMore
                      ? 'Loading…'
                      : remainingCount > 0
                      ? 'Load more ($remainingCount remaining)'
                      : 'Load more',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: child,
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: vcare.muted.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: vcare.mutedForeground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: vcare.mutedForeground,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.membership, required this.showClientName});

  final PendingMembership membership;
  final bool showClientName;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final offering = membership.offering;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: VCareRadius.lgAll,
        border: Border.all(color: vcare.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showClientName) ...[
                        Text(
                          membership.client.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        offering.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: showClientName ? 12 : 13,
                          fontWeight: showClientName
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: showClientName ? vcare.mutedForeground : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PendingMembershipStatusBadge(status: membership.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        formatMembershipMoney(offering.fee),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          formatMembershipFeeCadenceLabel(offering),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: vcare.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMembershipDate(membership.benefitStartDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (membershipRelationshipLabel(membership) != null) ...[
              const SizedBox(height: 8),
              PendingMembershipRelationshipChip(membership: membership),
            ],
          ],
        ),
      ),
    );
  }
}
