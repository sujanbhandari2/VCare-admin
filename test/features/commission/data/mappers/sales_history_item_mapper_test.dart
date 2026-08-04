import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/commission/data/mappers/sales_history_item_mapper.dart';
import 'package:vcare_admin/features/commission/data/models/sales_history_item_model.dart';
import 'package:vcare_admin/features/commission/domain/entities/sales_transaction_status.dart';

void main() {
  group('SalesHistoryItemModelMapper', () {
    test('maps sales history item from API payload', () {
      final model = SalesHistoryItemModel.fromJson({
        'id': '9a8b7c6d-0000-4000-8000-000000000000',
        'tenantId': '1f0e8a2b-0000-4000-8000-000000000000',
        'payerId': '7c8d9e0f-0000-4000-8000-000000000000',
        'payer': {
          'id': '7c8d9e0f-0000-4000-8000-000000000000',
          'name': 'Jane Doe',
          'email': 'jane@example.com',
          'phoneNumber': '+15551234567',
          'address': {
            'line1': '123 Main St',
            'city': 'Austin',
            'state': 'TX',
            'zip': '78701',
          },
          'profileId': null,
          'profilePreviewLink': null,
        },
        'subscriptionId': '4b5c6d7e-0000-4000-8000-000000000000',
        'paymentMethodId': '2a3b4c5d-0000-4000-8000-000000000000',
        'paymentMethod': {
          'id': '2a3b4c5d-0000-4000-8000-000000000000',
          'type': 'card',
          'cardBrand': 'visa',
          'cardLast4': '4242',
          'cardExpMonth': 12,
          'cardExpYear': 2028,
          'nickname': null,
        },
        'type': 'MEMBERSHIP_SUBSCRIPTION',
        'status': 'PAID',
        'amount': 500.0,
        'currency': 'usd',
        'commissionAmount': 75.0,
        'billingStartDate': '2026-07-01',
        'billingEndDate': '2026-07-31',
        'transactionDate': '2026-07-01T12:00:00.000Z',
        'invoiceNumber': 'INV-1001',
        'createdAt': '2026-07-01T12:00:00.000Z',
        'updatedAt': '2026-07-01T12:00:00.000Z',
      });

      final entity = model.toEntity();

      expect(entity.id, '9a8b7c6d-0000-4000-8000-000000000000');
      expect(entity.payerId, '7c8d9e0f-0000-4000-8000-000000000000');
      expect(entity.payer?.name, 'Jane Doe');
      expect(entity.payer?.address?.city, 'Austin');
      expect(entity.paymentMethod?.cardLast4, '4242');
      expect(entity.status, SalesTransactionStatus.paid);
      expect(entity.amount, 500.0);
      expect(entity.commissionAmount, 75.0);
      expect(entity.displayPayerName, 'Jane Doe');
    });

    test('preserves null commissionAmount for agency-associated items', () {
      final model = SalesHistoryItemModel.fromJson({
        'id': 'sale-1',
        'payerId': 'payer-1',
        'payer': {'id': 'payer-1', 'name': 'Acme Corp'},
        'status': 'PENDING',
        'amount': 250.0,
        'currency': 'usd',
        'commissionAmount': null,
        'transactionDate': '2026-07-01T08:00:00.000Z',
      });

      final entity = model.toEntity();

      expect(entity.status, SalesTransactionStatus.pending);
      expect(entity.amount, 250.0);
      expect(entity.commissionAmount, isNull);
    });

    test('maps transaction status values', () {
      SalesTransactionStatus mapStatus(String status) {
        return SalesHistoryItemModel.fromJson({
          'id': 'sale-1',
          'status': status,
          'amount': 1,
          'transactionDate': '2026-07-01T08:00:00.000Z',
        }).toEntity().status;
      }

      expect(mapStatus('FAILED'), SalesTransactionStatus.failed);
      expect(mapStatus('REFUNDED'), SalesTransactionStatus.refunded);
      expect(mapStatus('VOIDED'), SalesTransactionStatus.voided);
    });
  });
}
