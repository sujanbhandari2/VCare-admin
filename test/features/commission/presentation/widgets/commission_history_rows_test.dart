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
  testWidgets('commission history row shows signed commission amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [VCareThemeExtension.light]),
        home: const Scaffold(
          body: CommissionHistoryRow(
            item: CommissionHistoryItem(
              id: 'item-1',
              clientId: 'client-1',
              clientName: 'Jane Doe',
              commissionValue: '5',
              commissionType: 'PERCENTAGE',
              commissionAmount: 12.5,
              status: CommissionStatus.paid,
              createdAt: '2026-07-01T12:00:00.000Z',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.textContaining('12.50'), findsOneWidget);
  });

  testWidgets('sales history row shows sale amount and transaction status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [VCareThemeExtension.light]),
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
    expect(find.text('Paid'), findsOneWidget);
    expect(find.textContaining('500.00'), findsOneWidget);
  });

  testWidgets('sales history empty filter uses sales copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [VCareThemeExtension.light]),
        home: const Scaffold(body: CommissionSalesHistoryEmptyFilter()),
      ),
    );

    expect(find.text('No sales for this filter.'), findsOneWidget);
  });
}
