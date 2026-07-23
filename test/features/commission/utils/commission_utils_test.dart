import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/commission/domain/entities/commission_filter.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';
import 'package:vcare_admin/features/commission/utils/commission_utils.dart';

void main() {
  group('commission_utils', () {
    const itemPaid = CommissionHistoryItem(
      id: '1',
      clientId: 'client-1',
      clientName: 'Jane Doe',
      commissionValue: '5',
      commissionType: 'PERCENTAGE',
      commissionAmount: 10,
      status: CommissionStatus.paid,
      createdAt: '2026-06-25T12:22:46.546Z',
    );

    const itemPending = CommissionHistoryItem(
      id: '2',
      clientId: 'client-2',
      commissionValue: '5',
      commissionType: 'PERCENTAGE',
      commissionAmount: 5,
      status: CommissionStatus.pending,
      createdAt: '2026-06-25T12:22:46.546Z',
    );

    test('maps status labels from API status', () {
      expect(commissionStatusLabel(CommissionStatus.pending), 'Pending');
      expect(commissionStatusLabel(CommissionStatus.paid), 'Paid');
      expect(commissionStatusLabel(CommissionStatus.cancelled), 'Rejected');
    });

    test('maps sales transaction status labels', () {
      expect(
        salesTransactionStatusLabel(SalesTransactionStatus.pending),
        'Pending',
      );
      expect(salesTransactionStatusLabel(SalesTransactionStatus.paid), 'Paid');
      expect(
        salesTransactionStatusLabel(SalesTransactionStatus.failed),
        'Failed',
      );
      expect(
        salesTransactionStatusLabel(SalesTransactionStatus.refunded),
        'Refunded',
      );
      expect(
        salesTransactionStatusLabel(SalesTransactionStatus.voided),
        'Voided',
      );
    });

    test('maps UI filters to API status values', () {
      expect(CommissionFilter.all.apiStatus, isNull);
      expect(CommissionFilter.paid.apiStatus, 'PAID');
      expect(CommissionFilter.rejected.apiStatus, 'REJECTED');
    });

    test('formats commission money and null amounts', () {
      final signed = formatCommissionMoney(1.16, signed: true);
      expect(signed, startsWith('+'));
      expect(signed, contains('1.16'));
      expect(formatCommissionMoney(null), '—');
    });

    test('formats commission rate labels', () {
      expect(commissionRateLabel(itemPaid), '5% commission');
      expect(
        commissionRateLabel(
          const CommissionHistoryItem(
            id: '3',
            clientId: 'client-3',
            commissionType: 'PERCENTAGE',
            status: CommissionStatus.pending,
            createdAt: '2026-06-25T12:22:46.546Z',
          ),
        ),
        '—',
      );
    });

    test('uses client name when available', () {
      expect(itemPaid.displayClientName, 'Jane Doe');
      expect(itemPending.displayClientName, 'Client client-2');
    });

    test('detects empty summary state', () {
      expect(
        isCommissionSummaryEmpty(totalSales: 0, historyEmpty: true),
        isTrue,
      );
      expect(
        isCommissionSummaryEmpty(totalSales: 100, historyEmpty: true),
        isFalse,
      );
      expect(
        isCommissionSummaryEmpty(totalSales: null, historyEmpty: true),
        isTrue,
      );
    });
  });
}
