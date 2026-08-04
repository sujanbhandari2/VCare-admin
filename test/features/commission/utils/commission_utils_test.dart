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
      expect(commissionStatusLabel(CommissionStatus.paid), 'Successful');
      expect(commissionStatusLabel(CommissionStatus.cancelled), 'Rejected');
      expect(commissionStatusLabel(CommissionStatus.failed), 'Failed');
      expect(commissionStatusLabel(CommissionStatus.upcoming), 'Upcoming');
    });

    test('resolves web-aligned history status labels', () {
      expect(
        resolveCommissionStatusLabel(
          const CommissionHistoryItem(
            id: '1',
            clientId: 'c1',
            commissionType: 'FLAT',
            status: CommissionStatus.failed,
            apiStatus: 'FAILED',
            createdAt: '2026-06-25T12:22:46.546Z',
          ),
        ),
        'Failed',
      );
      expect(
        resolveCommissionStatusLabel(
          const CommissionHistoryItem(
            id: '2',
            clientId: 'c1',
            commissionType: 'FLAT',
            status: CommissionStatus.upcoming,
            apiStatus: 'UPCOMING',
            createdAt: '2026-06-25T12:22:46.546Z',
          ),
        ),
        'Upcoming',
      );
      expect(
        resolveCommissionStatusLabel(
          const CommissionHistoryItem(
            id: 'pending:abc',
            clientId: 'c1',
            commissionType: 'FLAT',
            itemType: 'ENROLLMENT',
            status: CommissionStatus.pending,
            apiStatus: 'PENDING',
            createdAt: '2026-06-25T12:22:46.546Z',
          ),
        ),
        'Upcoming',
      );
      expect(
        resolveCommissionStatusLabel(
          const CommissionHistoryItem(
            id: '3',
            clientId: 'c1',
            commissionType: 'FLAT',
            status: CommissionStatus.paid,
            apiStatus: 'PAID',
            createdAt: '2026-06-25T12:22:46.546Z',
          ),
        ),
        'Successful',
      );
      expect(
        resolveCommissionStatusLabel(
          const CommissionHistoryItem(
            id: '4',
            clientId: 'c1',
            commissionType: 'FLAT',
            status: CommissionStatus.pending,
            apiStatus: 'PENDING',
            createdAt: '2026-06-25T12:22:46.546Z',
          ),
        ),
        'Pending',
      );
    });

    test('aggregates sale totals skipping null sales amounts', () {
      final totals = aggregateSaleTotals([
        const CommissionHistoryItem(
          id: '1',
          clientId: 'c1',
          commissionType: 'FLAT',
          salesAmount: 100,
          status: CommissionStatus.upcoming,
          apiStatus: 'UPCOMING',
          createdAt: '2026-06-25T12:22:46.546Z',
        ),
        const CommissionHistoryItem(
          id: '2',
          clientId: 'c2',
          commissionType: 'FLAT',
          salesAmount: null,
          status: CommissionStatus.upcoming,
          apiStatus: 'UPCOMING',
          createdAt: '2026-06-25T12:22:46.546Z',
        ),
        const CommissionHistoryItem(
          id: '3',
          clientId: 'c3',
          commissionType: 'FLAT',
          salesAmount: 50.5,
          status: CommissionStatus.failed,
          apiStatus: 'FAILED',
          createdAt: '2026-06-25T12:22:46.546Z',
        ),
      ]);
      expect(totals.total, 150.5);
      expect(totals.count, 2);
    });

    test('maps sales transaction status labels', () {
      expect(
        salesTransactionStatusLabel(SalesTransactionStatus.pending),
        'Upcoming',
      );
      expect(
        salesTransactionStatusLabel(SalesTransactionStatus.paid),
        'Earned',
      );
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
      expect(formatCommissionMoney(500, currency: 'usd'), contains('500.00'));
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
      expect(itemPending.displayClientName, 'Client CLIENT2');
    });

    test('formats short transaction refs', () {
      expect(
        formatShortTransactionRef('64608a3c-4f0e-4b21-b154-8c6457ccdd02'),
        '#DD02',
      );
      expect(formatShortTransactionRef(null), '—');
    });

    test('detects empty summary state', () {
      expect(
        isCommissionSummaryEmpty(totalSales: 0, historyEmpty: true),
        isTrue,
      );
      expect(
        isCommissionSummaryEmpty(
          totalSales: 0,
          totalCommission: 0,
          historyEmpty: true,
        ),
        isTrue,
      );
      expect(
        isCommissionSummaryEmpty(totalSales: 100, historyEmpty: true),
        isFalse,
      );
      expect(
        isCommissionSummaryEmpty(
          totalSales: 0,
          totalCommission: 25,
          historyEmpty: true,
        ),
        isFalse,
      );
      expect(
        isCommissionSummaryEmpty(totalSales: null, historyEmpty: true),
        isTrue,
      );
      expect(
        isCommissionSummaryEmpty(
          totalSales: 0,
          upcomingCount: 1,
          historyEmpty: true,
        ),
        isFalse,
      );
      expect(
        isCommissionSummaryEmpty(
          totalSales: 0,
          needsAttentionCount: 2,
          historyEmpty: true,
        ),
        isFalse,
      );
    });
  });
}
