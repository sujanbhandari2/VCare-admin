import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_button_styles.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/pending_memberships/domain/entities/pending_membership.dart';
import 'package:vcare_admin/features/pending_memberships/presentation/widgets/pending_membership_chips.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_button_styles.dart';
import 'package:vcare_admin/features/pending_memberships/utils/pending_membership_formatters.dart';

/// Pending membership card — client identity on top, then the membership
/// with its fee, benefit date, and the inline Approve action.
class PendingMembershipRow extends StatelessWidget {
  const PendingMembershipRow({
    super.key,
    required this.membership,
    this.onTap,
    this.onApprove,
  });

  /// Fixed width for the fee column so the Approve button never has to shrink
  /// below its label, whatever the device width.
  static const double _feeColumnWidth = 116;

  final PendingMembership membership;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final client = membership.client;
    final offering = membership.offering;
    final registrationFee = offering.registrationFee ?? 0;
    final email = client.email?.trim();
    final canApprove = membership.status.isSubmitted && onApprove != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: VCareRadius.lgAll,
        child: Ink(
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          if (email != null && email.isNotEmpty)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.3,
                                color: vcare.mutedForeground,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: vcare.border),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offering.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          PendingMembershipRelationshipChip(
                            membership: membership,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${formatMembershipFeeCadenceLabel(offering)} '
                            '${formatMembershipMoney(offering.fee)}',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: vcare.mutedForeground,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (registrationFee > 0)
                            Text(
                              'Reg fee '
                              '${formatMembershipMoney(registrationFee)}',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: vcare.mutedForeground,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: _feeColumnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Benefit date',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: vcare.mutedForeground,
                            ),
                          ),
                          Text(
                            formatMembershipDate(membership.benefitStartDate),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: vcare.mutedForeground,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (canApprove) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: onApprove,
                                style: pendingMembershipApproveButtonStyle(
                                  size: VCareButtonSize.sm,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                icon: const Icon(
                                  LucideIcons.checkCircle,
                                  size: 13,
                                ),
                                label: const Text('Approve'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
