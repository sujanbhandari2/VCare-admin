import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_row.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';

Future<void> showCommissionDetailSheet(
  BuildContext context,
  CommissionHistoryItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    barrierColor: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => CommissionDetailSheet(item: item),
  );
}

class CommissionDetailSheet extends StatelessWidget {
  const CommissionDetailSheet({super.key, required this.item});

  final CommissionHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final timeline = _buildTimeline(item);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: vcare.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Text(
                'Commission details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Client',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: vcare.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.displayClientName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CommissionStatusBadge(
                          label: commissionStatusLabel(item.status),
                          status: item.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: vcare.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: vcare.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Commission rate',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: vcare.mutedForeground,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      commissionRateLabel(item),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCommissionMoney(item.commissionAmount),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Commission',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: vcare.mutedForeground,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'For this plan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCommissionMoney(item.commissionAmount),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: VCareColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Timeline',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ...timeline.map((step) => _TimelineStepRow(step: step)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TimelineStepState { done, current, failed, pending }

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.dateLabel,
    required this.state,
  });

  final String label;
  final String dateLabel;
  final _TimelineStepState state;
}

List<_TimelineStep> _buildTimeline(CommissionHistoryItem item) {
  final processedDate = formatClientDateNumeric(item.createdAt);
  final paidDate = item.paidAt == null
      ? null
      : formatClientDateNumeric(item.paidAt!);

  return switch (item.status) {
    CommissionStatus.cancelled => [
        _TimelineStep(
          label: 'Processed',
          dateLabel: processedDate,
          state: _TimelineStepState.done,
        ),
        _TimelineStep(
          label: 'Failed',
          dateLabel: processedDate,
          state: _TimelineStepState.failed,
        ),
        const _TimelineStep(
          label: 'Paid',
          dateLabel: 'Awaiting next step',
          state: _TimelineStepState.pending,
        ),
      ],
    CommissionStatus.pending => [
        _TimelineStep(
          label: 'Processed',
          dateLabel: processedDate,
          state: _TimelineStepState.done,
        ),
        const _TimelineStep(
          label: 'Pending payout',
          dateLabel: 'Awaiting next step',
          state: _TimelineStepState.current,
        ),
      ],
    CommissionStatus.paid => [
        _TimelineStep(
          label: 'Processed',
          dateLabel: processedDate,
          state: _TimelineStepState.done,
        ),
        _TimelineStep(
          label: 'Paid out',
          dateLabel: paidDate ?? processedDate,
          state: _TimelineStepState.done,
        ),
      ],
    CommissionStatus.unknown => [
        _TimelineStep(
          label: 'Processed',
          dateLabel: processedDate,
          state: _TimelineStepState.done,
        ),
      ],
  };
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({required this.step});

  final _TimelineStep step;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final labelColor = switch (step.state) {
      _TimelineStepState.failed => VCareColors.destructive,
      _TimelineStepState.pending => vcare.mutedForeground,
      _ => VCareColors.foreground,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineIcon(state: step.state),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: vcare.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineIcon extends StatelessWidget {
  const _TimelineIcon({required this.state});

  final _TimelineStepState state;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    final (background, foreground, icon) = switch (state) {
      _TimelineStepState.done => (
          VCareColors.success,
          VCareColors.successForeground,
          LucideIcons.check,
        ),
      _TimelineStepState.failed => (
          VCareColors.destructive,
          VCareColors.destructiveForeground,
          LucideIcons.x,
        ),
      _TimelineStepState.current => (
          const Color(0xFFF59E0B),
          Colors.white,
          LucideIcons.clock,
        ),
      _TimelineStepState.pending => (
          vcare.muted,
          vcare.mutedForeground,
          null,
        ),
    };

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: state == _TimelineStepState.pending
            ? Border.all(color: vcare.border, width: 2)
            : null,
      ),
      child: icon == null
          ? null
          : Icon(icon, size: 14, color: foreground),
    );
  }
}
