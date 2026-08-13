import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_history_item.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_history_row.dart';
import 'package:vcare_admin/features/commission/presentation/widgets/commission_sales_history_row.dart';

void main() {
  testWidgets('commission history row shows sale, commission, and status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [VCareThemeExtension.light]),
        home: const Scaffold(
          body: CommissionHistoryRow(
            item: CommissionHistoryItem(
              id: 'item-1',
              clientId: 'client-1',
              clientName: 'Jane Doe',
              commissionValue: '5',
              commissionType: 'PERCENTAGE',
              commissionAmount: 12.5,
              salesAmount: 250,
              status: CommissionStatus.paid,
              apiStatus: 'PAID',
              createdAt: '2026-07-01T12:00:00.000Z',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.textContaining('250.00'), findsOneWidget);
    expect(find.textContaining('12.50'), findsOneWidget);
    expect(find.text('Successful'), findsOneWidget);
  });

  testWidgets('sales history row shows sale amount and status badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [VCareThemeExtension.light]),
        home: const Scaffold(
          body: CommissionSalesHistoryRow(
            item: SalesHistoryItem(
              id: 'sale-1',
              payerId: 'payer-1',
              payer: SalesHistoryPayer(id: 'payer-1', name: 'Acme Corp'),
              status: SalesTransactionStatus.paid,
              amount: 500,
              currency: 'usd',
              transactionDate: '2026-07-01T12:00:00.000Z',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Acme Corp'), findsOneWidget);
    expect(find.textContaining('500.00'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
  });

  testWidgets('failed sales row shows failed-to-collect hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [VCareThemeExtension.light]),
        home: const Scaffold(
          body: CommissionSalesHistoryRow(
            item: SalesHistoryItem(
              id: 'sale-2',
              payerId: 'payer-2',
              payer: SalesHistoryPayer(id: 'payer-2', name: 'Failed Client'),
              status: SalesTransactionStatus.failed,
              amount: 120,
              currency: 'usd',
              transactionDate: '2026-07-01T12:00:00.000Z',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Failed Client'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Failed to collect'), findsOneWidget);
  });

  testWidgets('sales history empty uses sales copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [VCareThemeExtension.light]),
        home: const Scaffold(body: CommissionSalesHistoryEmptyFilter()),
      ),
    );

    expect(find.text('No sales yet.'), findsOneWidget);
  });
}
