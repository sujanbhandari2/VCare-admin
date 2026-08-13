import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/utils/client_utils.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_earnings_columns.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_status_pill.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';

/// Compact individual row: client + date, then sale + commission + status.
///
/// parity: vcare-agent-app-2.0/src/features/commission/components/CommissionHistoryList.tsx
class CommissionHistoryRow extends StatelessWidget {
  const CommissionHistoryRow({super.key, required this.item, this.onTap});

  final CommissionHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final statusLabel = resolveCommissionStatusLabel(item);
    final isFailed = statusLabel == 'Failed' || statusLabel == 'Rejected';
    final photoUrl = item.clientPhotoUrl?.trim();
    final offering = item.offeringName?.trim();
    final initials = _clientInitials(item.displayClientName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: CommissionEarningsColumns.rowPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _ClientAvatar(photoUrl: photoUrl, initials: initials),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayClientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (offering != null && offering.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              offering,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: vcare.mutedForeground,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            formatClientDateNumeric(item.displayDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: CommissionEarningsColumns.gap),
              CommissionAmountCell(
                width: CommissionEarningsColumns.saleWidth,
                child: Text(
                  formatCommissionMoney(item.salesAmount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isFailed ? vcare.destructive : null,
                  ),
                ),
              ),
              const SizedBox(width: CommissionEarningsColumns.gap),
              CommissionAmountCell(
                width: CommissionEarningsColumns.commissionWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCommissionMoney(item.commissionAmount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFailed ? vcare.destructive : vcare.success,
                      ),
                    ),
                    const SizedBox(height: 3),
                    CommissionStatusPill(label: statusLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clientInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final list = parts.toList();
  if (list.length == 1) {
    return list.first.substring(0, list.first.length.clamp(0, 2)).toUpperCase();
  }
  final first = list.first[0];
  final last = list.last[0];
  return '$first$last'.toUpperCase();
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.photoUrl, required this.initials});

  final String? photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final url = photoUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 32,
        height: 32,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _InitialsBubble(
                  initials: initials,
                  background: vcare.muted,
                  foreground: vcare.mutedForeground,
                ),
              )
            : _InitialsBubble(
                initials: initials,
                background: vcare.muted,
                foreground: vcare.mutedForeground,
              ),
      ),
    );
  }
}

class _InitialsBubble extends StatelessWidget {
  const _InitialsBubble({
    required this.initials,
    required this.background,
    required this.foreground,
  });

  final String initials;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class CommissionHistoryEmptyFilter extends StatelessWidget {
  const CommissionHistoryEmptyFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: vcare.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vcare.border, style: BorderStyle.solid),
      ),
      child: Text(
        'No commissions yet.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: vcare.mutedForeground),
      ),
    );
  }
}
