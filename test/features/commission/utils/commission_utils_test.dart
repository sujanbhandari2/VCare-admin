import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';

void main() {
  group('commission_utils', () {
    const itemPaid = CommissionHistoryItem(
      id: '1',
      clientId: 'client-1',
      clientName: 'Jane Doe',
      commissionValue: '5',
      commissionType: 'PERCENTAGE',
      commissionAmount: '10',
      status: CommissionStatus.paid,
      createdAt: '2026-06-25T12:22:46.546Z',
    );

    const itemPending = CommissionHistoryItem(
      id: '2',
      clientId: 'client-2',
      commissionValue: '5',
      commissionType: 'PERCENTAGE',
      commissionAmount: '5',
      status: CommissionStatus.pending,
      createdAt: '2026-06-25T12:22:46.546Z',
    );

    test('maps status labels to web parity', () {
      expect(commissionStatusLabel(CommissionStatus.paid), 'Paid');
      expect(commissionStatusLabel(CommissionStatus.pending), 'Earned');
      expect(commissionStatusLabel(CommissionStatus.cancelled), 'Failed');
    });

    test('filters history by status', () {
      final filtered = filterCommissionHistory(
        const [itemPaid, itemPending],
        CommissionFilter.earned,
      );

      expect(filtered, [itemPending]);
    });

    test('uses client name when available', () {
      expect(itemPaid.displayClientName, 'Jane Doe');
    });

    test('detects empty summary state', () {
      expect(
        isCommissionSummaryEmpty(totalSales: '0', historyEmpty: true),
        isTrue,
      );
      expect(
        isCommissionSummaryEmpty(totalSales: '100', historyEmpty: true),
        isFalse,
      );
    });
  });
}
