import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_spacing.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

class ClientStatusChip extends StatelessWidget {
  const ClientStatusChip({super.key, required this.label, this.tone});

  factory ClientStatusChip.membership(ClientMembershipStatus status) {
    return ClientStatusChip(
      label: _membershipLabel(status),
      tone: _membershipTone(status),
    );
  }

  factory ClientStatusChip.transaction(ClientTransactionStatus status) {
    return ClientStatusChip(
      label: _transactionLabel(status),
      tone: _transactionTone(status),
    );
  }

  factory ClientStatusChip.caseStatus(ClientCaseStatus status) {
    return ClientStatusChip(label: _caseLabel(status), tone: _caseTone(status));
  }

  factory ClientStatusChip.billing(ClientBillingStatus status) {
    return ClientStatusChip(
      label: _billingLabel(status),
      tone: _billingTone(status),
    );
  }

  final String label;
  final ClientChipTone? tone;

  static String _membershipLabel(ClientMembershipStatus status) {
    switch (status) {
      case ClientMembershipStatus.approved:
        return 'Approved';
      case ClientMembershipStatus.submitted:
        return 'Submitted';
      case ClientMembershipStatus.completed:
        return 'Completed';
      case ClientMembershipStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ClientChipTone _membershipTone(ClientMembershipStatus status) {
    switch (status) {
      case ClientMembershipStatus.approved:
        return ClientChipTone.success;
      case ClientMembershipStatus.submitted:
        return ClientChipTone.info;
      case ClientMembershipStatus.completed:
      case ClientMembershipStatus.cancelled:
        return ClientChipTone.muted;
    }
  }

  static String _transactionLabel(ClientTransactionStatus status) {
    switch (status) {
      case ClientTransactionStatus.succeeded:
        return 'Succeeded';
      case ClientTransactionStatus.failed:
        return 'Failed';
      case ClientTransactionStatus.onHold:
        return 'On Hold';
      case ClientTransactionStatus.pending:
        return 'Pending';
    }
  }

  static ClientChipTone _transactionTone(ClientTransactionStatus status) {
    switch (status) {
      case ClientTransactionStatus.succeeded:
        return ClientChipTone.success;
      case ClientTransactionStatus.failed:
        return ClientChipTone.destructive;
      case ClientTransactionStatus.onHold:
        return ClientChipTone.warning;
      case ClientTransactionStatus.pending:
        return ClientChipTone.warning;
    }
  }

  static String _caseLabel(ClientCaseStatus status) {
    switch (status) {
      case ClientCaseStatus.requested:
        return 'Requested';
      case ClientCaseStatus.inProgress:
        return 'In Progress';
      case ClientCaseStatus.resolved:
        return 'Resolved';
    }
  }

  static ClientChipTone _caseTone(ClientCaseStatus status) {
    switch (status) {
      case ClientCaseStatus.requested:
        return ClientChipTone.muted;
      case ClientCaseStatus.inProgress:
        return ClientChipTone.info;
      case ClientCaseStatus.resolved:
        return ClientChipTone.success;
    }
  }

  static String _billingLabel(ClientBillingStatus status) {
    switch (status) {
      case ClientBillingStatus.paid:
        return 'Paid';
      case ClientBillingStatus.pending:
        return 'Pending';
      case ClientBillingStatus.overdue:
        return 'Overdue';
    }
  }

  static ClientChipTone _billingTone(ClientBillingStatus status) {
    switch (status) {
      case ClientBillingStatus.paid:
        return ClientChipTone.success;
      case ClientBillingStatus.pending:
        return ClientChipTone.warning;
      case ClientBillingStatus.overdue:
        return ClientChipTone.destructive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = VCareStatusColors.of(
      context,
      _toStatusTone(tone ?? ClientChipTone.muted),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VCareSpacing.s2,
        vertical: VCareSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: VCareRadius.fullAll,
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

  static VCareStatusTone _toStatusTone(ClientChipTone tone) {
    return switch (tone) {
      ClientChipTone.success => VCareStatusTone.success,
      ClientChipTone.warning => VCareStatusTone.warning,
      ClientChipTone.destructive => VCareStatusTone.danger,
      ClientChipTone.info => VCareStatusTone.info,
      ClientChipTone.muted => VCareStatusTone.neutral,
    };
  }
}

enum ClientChipTone { success, warning, destructive, info, muted }
