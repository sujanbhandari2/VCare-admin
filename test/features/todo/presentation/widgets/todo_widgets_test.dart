import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/home/presentation/widgets/home_recent_activity_section.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_list_row.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_w9_form_sheet.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';

import '../../../../fixtures/repositories/fake_client_repository.dart';

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
      failureReason: 'Insufficient funds',
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

TodoItem _completeProfileTodo() {
  return TodoItem(
    id: 'complete-profile:agent-1',
    type: TodoType.completeProfile,
    title: 'Complete your profile',
    description: 'Add a photo and bio to finish your profile.',
    occurredAt: DateTime.utc(2026, 7, 21, 5),
    resource: const TodoResource(type: 'AGENT', id: 'agent-1'),
    rawType: 'COMPLETE_PROFILE',
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
      expect(find.text('Not enough funds'), findsOneWidget);
      expect(find.textContaining('99.50'), findsOneWidget);
    });

    testWidgets('renders W-9 action needed chip', (tester) async {
      await tester.pumpWidget(_wrap(TodoListRow(item: _w9Todo())));

      expect(find.text('W-9 needed'), findsOneWidget);
      expect(find.text('Action needed'), findsOneWidget);
      expect(find.text('Upload a W-9 for the profile.'), findsOneWidget);
    });

    testWidgets('renders complete profile action needed chip', (tester) async {
      await tester.pumpWidget(_wrap(TodoListRow(item: _completeProfileTodo())));

      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Action needed'), findsOneWidget);
      expect(
        find.text('Add a photo and bio to finish your profile.'),
        findsOneWidget,
      );
    });
  });

  group('TodoTransactionDetailSheet', () {
    testWidgets('shows recovery paths for failed payment', (tester) async {
      final clients = FakeClientRepository()
        ..fetchPaymentMethodsResult = Success(const [
          ClientPaymentMethod(
            id: 'pm-primary',
            type: ClientPaymentMethodType.creditDebitCard,
            label: 'Visa •• 4242',
            last4: '4242',
            expMonth: 12,
            expYear: 2030,
            isPrimary: true,
          ),
          ClientPaymentMethod(
            id: 'pm-other',
            type: ClientPaymentMethodType.creditDebitCard,
            label: 'Mastercard •• 4444',
            last4: '4444',
            expMonth: 6,
            expYear: 2029,
          ),
        ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientRepositoryProvider.overrideWith((ref) => clients),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: const [VCareThemeExtension.light]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TodoTransactionDetailSheet(item: _paymentFailedTodo()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("We couldn't process this payment"), findsOneWidget);
      expect(find.text('RECOVER THIS PAYMENT'), findsOneWidget);
      expect(find.text('Charge a card on file'), findsOneWidget);
      expect(find.text('Add a card'), findsOneWidget);
      expect(find.text('Add card & charge'), findsOneWidget);
      expect(find.text('Try the same card again'), findsOneWidget);
      expect(find.text('Retry payment'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.textContaining('Not enough funds'), findsOneWidget);
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
