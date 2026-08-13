import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';
import 'package:vcare_admin/features/clients/presentation/providers/client_repository_provider.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_item.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_list_row.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_transaction_detail_sheet.dart';
import 'package:vcare_admin/features/todo/presentation/widgets/todo_w9_form_sheet.dart';
import 'package:vcare_admin/l10n/app_localizations.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';
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
      theme: ThemeData(extensions: [VCareThemeExtension.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
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
    Widget wrapSheet(FakeClientRepository clients) {
      return ProviderScope(
        overrides: [
          clientRepositoryProvider.overrideWith((ref) => clients),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [VCareThemeExtension.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodoTransactionDetailSheet(item: _paymentFailedTodo()),
          ),
        ),
      );
    }

    testWidgets('shimmers the recovery paths while the cards load', (
      tester,
    ) async {
      final gate = Completer<void>();
      final clients = FakeClientRepository()
        ..fetchPaymentMethodsDelay = gate.future;

      await tester.pumpWidget(wrapSheet(clients));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.text('Add a card'), findsNothing);
      // The failure details come from the todo itself, so they stay visible.
      expect(find.textContaining('99.50'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(Shimmer), findsNothing);
      expect(find.text('Add a card'), findsOneWidget);
    });

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

      await tester.pumpWidget(wrapSheet(clients));
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
