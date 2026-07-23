import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_recent_activity_section.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_list_row.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_w9_form_sheet.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';

TodoItem _paymentFailedTodo({
  String id = 'payment-failed:txn-1',
  String transactionId = 'txn-1',
}) {
  return TodoItem(
    id: id,
    type: TodoType.paymentFailed,
    title: 'Payment failed',
    description: "Jane Doe's payment of USD 99.5 failed",
    occurredAt: DateTime.utc(2026, 7, 21, 5),
    resource: TodoResource(type: 'TRANSACTION', id: transactionId),
    paymentFailedDetails: TodoPaymentFailedDetails(
      transactionId: transactionId,
      payerId: 'payer-1',
      payerName: 'Jane Doe',
      amount: 99.5,
      currency: 'USD',
      invoiceNumber: 'INV-100',
    ),
  );
}

TodoItem _w9Todo() {
  return TodoItem(
    id: 'w9:abc',
    type: TodoType.w9FormMissing,
    title: 'W-9 needed',
    description: 'Upload a W-9 for the profile.',
    occurredAt: DateTime.utc(2026, 7, 21, 5),
    resource: const TodoResource(type: 'AGENT', id: 'agent-1'),
    w9FormDetails: const TodoW9FormDetails(
      documentType: 'W-9 Form',
      agentId: 'agent-1',
    ),
    rawType: 'W9_FORM_REQUIRED',
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(extensions: const [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('HomeRecentActivitySection', () {
    testWidgets('shows empty state when there are no todos', (tester) async {
      await tester.pumpWidget(
        _wrap(const HomeRecentActivitySection(items: [])),
      );

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('See all'), findsNothing);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        _wrap(const HomeRecentActivitySection(items: [], isLoading: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error panel with retry', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(
          HomeRecentActivitySection(
            items: const [],
            isError: true,
            errorMessage: 'Boom',
            onRetry: () => retries += 1,
          ),
        ),
      );

      expect(find.text('Unable to load tasks'), findsOneWidget);
      await tester.tap(find.textContaining('Retry'));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('shows preview rows and see all when items exist', (
      tester,
    ) async {
      var seeAllTaps = 0;
      var itemTaps = 0;
      final items = [
        _paymentFailedTodo(),
        _paymentFailedTodo(id: 'payment-failed:txn-2', transactionId: 'txn-2'),
      ];

      await tester.pumpWidget(
        _wrap(
          HomeRecentActivitySection(
            items: items,
            onSeeAll: () => seeAllTaps += 1,
            onItemTap: (_) => itemTaps += 1,
          ),
        ),
      );

      expect(find.byType(TodoListRow), findsNWidgets(2));
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('Payment failed'), findsNWidgets(2));

      await tester.tap(find.text('See all'));
      await tester.pump();
      expect(seeAllTaps, 1);

      await tester.tap(find.byType(TodoListRow).first);
      await tester.pump();
      expect(itemTaps, 1);
    });
  });

  group('TodoListRow', () {
    testWidgets('renders payment failed amount and status', (tester) async {
      await tester.pumpWidget(_wrap(TodoListRow(item: _paymentFailedTodo())));

      expect(find.text('Payment failed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.textContaining('99.50'), findsOneWidget);
    });

    testWidgets('renders W-9 action needed chip', (tester) async {
      await tester.pumpWidget(_wrap(TodoListRow(item: _w9Todo())));

      expect(find.text('W-9 needed'), findsOneWidget);
      expect(find.text('Action needed'), findsOneWidget);
      expect(find.text('Upload a W-9 for the profile.'), findsOneWidget);
    });
  });

  group('TodoTransactionDetailSheet', () {
    testWidgets('shows available fields and reprocess action', (tester) async {
      await tester.pumpWidget(
        _wrap(TodoTransactionDetailSheet(item: _paymentFailedTodo())),
      );

      expect(find.text('Transaction details'), findsOneWidget);
      expect(find.text('INV-100'), findsOneWidget);
      expect(find.text('Billed to Jane Doe'), findsOneWidget);
      expect(find.text('Reprocess'), findsOneWidget);
      expect(find.text('Receipt'), findsNothing);
      expect(find.text('Add note'), findsNothing);
      expect(find.text('Email'), findsNothing);
    });
  });

  group('TodoW9FormSheet', () {
    testWidgets('shows download fill and upload steps', (tester) async {
      await tester.pumpWidget(_wrap(TodoW9FormSheet(item: _w9Todo())));

      expect(find.text('Complete your W-9'), findsOneWidget);
      expect(find.text('Download the blank form'), findsOneWidget);
      expect(find.text('Fill it out and sign'), findsOneWidget);
      expect(find.text('Upload your signed PDF'), findsOneWidget);
      expect(find.text('Choose file to upload'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
    });
  });
}
