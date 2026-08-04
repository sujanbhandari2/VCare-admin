import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/todo/data/mappers/todo_item_mapper.dart';
import 'package:vcare_admin/features/todo/data/models/todo_item_model.dart';
import 'package:vcare_admin/features/todo/domain/entities/todo_type.dart';

void main() {
  group('TodoItemModelMapper', () {
    test('maps payment failed todo from web API payload', () {
      final model = TodoItemModel.fromJson({
        'id': 'payment-failed:txn-1',
        'type': 'PAYMENT_FAILED',
        'title': 'Payment failed',
        'description': "Jane Doe's payment of USD 99.5 failed",
        'occurredAt': '2026-07-21T05:00:00.000Z',
        'resource': {'type': 'TRANSACTION', 'id': 'txn-1'},
        'details': {
          'name': 'Jane Doe',
          'amount': '99.5',
          'currency': 'USD',
          'code': 'INV-100',
          'relatedId': 'payer-1',
          'reason': 'Insufficient funds',
        },
      });

      final entity = model.toEntity();

      expect(entity.id, 'payment-failed:txn-1');
      expect(entity.type, TodoType.paymentFailed);
      expect(entity.title, 'Payment failed');
      expect(entity.description, "Jane Doe's payment of USD 99.5 failed");
      expect(
        entity.occurredAt.toUtc().toIso8601String(),
        '2026-07-21T05:00:00.000Z',
      );
      expect(entity.resource?.type, 'TRANSACTION');
      expect(entity.resource?.id, 'txn-1');
      expect(entity.paymentFailedDetails?.transactionId, 'txn-1');
      expect(entity.paymentFailedDetails?.payerId, 'payer-1');
      expect(entity.paymentFailedDetails?.payerName, 'Jane Doe');
      expect(entity.paymentFailedDetails?.amount, 99.5);
      expect(entity.paymentFailedDetails?.currency, 'USD');
      expect(entity.paymentFailedDetails?.invoiceNumber, 'INV-100');
      expect(entity.paymentFailedDetails?.failureReason, 'Insufficient funds');
      expect(entity.transactionId, 'txn-1');
      expect(entity.displayPayerName, 'Jane Doe');
    });

    test('maps payment failed todo from legacy Flutter-shaped details', () {
      final model = TodoItemModel.fromJson({
        'id': 'payment-failed:txn-1',
        'type': 'PAYMENT_FAILED',
        'title': 'Payment failed',
        'description': "Jane Doe's payment of USD 99.5 failed",
        'occurredAt': '2026-07-21T05:00:00.000Z',
        'resource': {'type': 'TRANSACTION', 'id': 'txn-1'},
        'details': {
          'transactionId': 'txn-1',
          'payerId': 'payer-1',
          'payerName': 'Jane Doe',
          'amount': '99.5',
          'currency': 'USD',
          'invoiceNumber': 'INV-100',
          'failureReason': 'Card declined',
        },
      });

      final entity = model.toEntity();

      expect(entity.paymentFailedDetails?.transactionId, 'txn-1');
      expect(entity.paymentFailedDetails?.payerId, 'payer-1');
      expect(entity.paymentFailedDetails?.payerName, 'Jane Doe');
      expect(entity.paymentFailedDetails?.invoiceNumber, 'INV-100');
      expect(entity.paymentFailedDetails?.failureReason, 'Card declined');
    });

    test('drops incomplete payment failed details', () {
      final model = TodoItemModel.fromJson({
        'id': 'payment-failed:txn-2',
        'type': 'PAYMENT_FAILED',
        'title': '',
        'description': '',
        'occurredAt': 'not-a-date',
        'details': {
          'transactionId': 'txn-2',
          'payerId': '',
          'payerName': '  ',
          'amount': 'bad',
          'currency': '',
        },
      });

      final entity = model.toEntity();

      expect(entity.title, 'Task');
      expect(entity.resource, isNull);
      expect(entity.paymentFailedDetails, isNull);
      expect(entity.displayPayerName, 'Client');
    });

    test('maps W9_FORM_REQUIRED todo with document type and cleaned subtitle', () {
      final model = TodoItemModel.fromJson({
        'id': 'w9:abc',
        'type': 'W9_FORM_REQUIRED',
        'title': 'W-9 needed',
        'description': 'Upload a W-9 for the agent profile',
        'occurredAt': '2026-07-21T05:00:00.000Z',
        'resource': {'type': 'AGENT', 'id': 'agent-1'},
        'details': {'code': 'W-9 Form'},
      });

      final entity = model.toEntity();

      expect(entity.type, TodoType.w9FormMissing);
      expect(entity.isW9FormMissing, isTrue);
      expect(entity.rawType, 'W9_FORM_REQUIRED');
      expect(entity.description, 'Upload a W-9 for the profile.');
      expect(entity.agentId, 'agent-1');
      expect(entity.w9FormDetails?.documentType, 'W-9 Form');
      expect(entity.w9DocumentTypeLabel, 'W-9 Form');
      expect(entity.paymentFailedDetails, isNull);
      expect(entity.transactionId, isNull);
    });

    test('maps W9_FORM_MISSING with default document type when code missing', () {
      final model = TodoItemModel.fromJson({
        'id': 'w9:def',
        'type': 'W9_FORM_MISSING',
        'title': 'Complete W-9',
        'description': 'Please upload your form',
        'occurredAt': '2026-07-21T05:00:00.000Z',
        'resource': {'type': 'AGENT', 'id': 'agent-2'},
        'details': {},
      });

      final entity = model.toEntity();

      expect(entity.type, TodoType.w9FormMissing);
      expect(entity.w9DocumentTypeLabel, 'W-9 Form');
      expect(entity.description, 'Please upload your form.');
    });

    test('maps COMPLETE_PROFILE todo with cleaned subtitle', () {
      final model = TodoItemModel.fromJson({
        'id': 'complete-profile:agent-1',
        'type': 'COMPLETE_PROFILE',
        'title': 'Complete your profile',
        'description': 'Add a photo and bio to finish your profile',
        'occurredAt': '2026-07-21T05:00:00.000Z',
        'resource': {'type': 'AGENT', 'id': 'agent-1'},
        'details': {},
      });

      final entity = model.toEntity();

      expect(entity.type, TodoType.completeProfile);
      expect(entity.isCompleteProfile, isTrue);
      expect(entity.rawType, 'COMPLETE_PROFILE');
      expect(
        entity.description,
        'Add a photo and bio to finish your profile.',
      );
      expect(entity.paymentFailedDetails, isNull);
      expect(entity.w9FormDetails, isNull);
    });

    test('maps unknown future type without payment details', () {
      final model = TodoItemModel.fromJson({
        'id': 'other:abc',
        'type': 'SOME_FUTURE_TYPE',
        'title': 'Future task',
        'description': 'Do something',
        'occurredAt': '2026-07-21T05:00:00.000Z',
        'resource': {'type': 'CLIENT', 'id': 'client-1'},
        'details': {'clientId': 'client-1'},
      });

      final entity = model.toEntity();

      expect(entity.type, TodoType.unknown);
      expect(entity.rawType, 'SOME_FUTURE_TYPE');
      expect(entity.paymentFailedDetails, isNull);
      expect(entity.w9FormDetails, isNull);
      expect(entity.transactionId, isNull);
    });
  });
}
