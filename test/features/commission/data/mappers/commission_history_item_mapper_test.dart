import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/commission/data/mappers/commission_history_item_mapper.dart';
import 'package:vcare_admin/features/commission/data/models/commission_history_item_model.dart';
import 'package:vcare_admin/features/commission/domain/entities/commission_status.dart';

void main() {
  group('CommissionHistoryItemModelMapper', () {
    test('maps commission history item from API payload', () {
      final model = CommissionHistoryItemModel.fromJson({
        'id': '90d500e3-b3bc-4873-9cc2-8e4142650692',
        'tenantId': '1b4b5118-055f-44e7-9ddd-59e5e357e756',
        'commissionSettingsId': '7910d1b9-27f5-4df5-ae0f-ae05b42ed9a0',
        'transactionId': '64608a3c-4f0e-4b21-b154-8c6457ccdd02',
        'agencyGroupId': null,
        'referrerAgentId': '0fd1c3ba-9498-46e9-98c5-2fa28e6aa15d',
        'clientId': 'ca0cf27a-e98c-4d77-b09e-a413c553067f',
        'clientName': 'Jane Doe',
        'commissionValue': '5',
        'commissionType': 'PERCENTAGE',
        'commissionAmount': 1.16,
        'salesAmount': 232.0,
        'status': 'PENDING',
        'paidAt': null,
        'notes': null,
        'createdAt': '2026-06-25T12:22:46.546Z',
        'updatedAt': '2026-06-25T12:22:46.546Z',
      });

      final entity = model.toEntity();

      expect(entity.id, '90d500e3-b3bc-4873-9cc2-8e4142650692');
      expect(entity.transactionId, '64608a3c-4f0e-4b21-b154-8c6457ccdd02');
      expect(entity.clientId, 'ca0cf27a-e98c-4d77-b09e-a413c553067f');
      expect(entity.clientName, 'Jane Doe');
      expect(entity.agencyGroupId, isNull);
      expect(entity.commissionValue, '5');
      expect(entity.commissionType, 'PERCENTAGE');
      expect(entity.commissionAmount, 1.16);
      expect(entity.salesAmount, 232.0);
      expect(entity.status, CommissionStatus.pending);
      expect(entity.paidAt, isNull);
      expect(entity.createdAt, '2026-06-25T12:22:46.546Z');
    });

    test('preserves null commission fields for agency-associated items', () {
      final model = CommissionHistoryItemModel.fromJson({
        'id': 'agency-1',
        'clientId': 'client-1',
        'clientName': 'Acme Corp',
        'agencyGroupId': 'ag-1111-2222-3333-4444-555555555555',
        'commissionValue': null,
        'commissionType': 'PERCENTAGE',
        'commissionAmount': null,
        'status': 'PENDING',
        'paidAt': null,
        'createdAt': '2026-07-01T08:00:00.000Z',
      });

      final entity = model.toEntity();

      expect(entity.agencyGroupId, 'ag-1111-2222-3333-4444-555555555555');
      expect(entity.commissionValue, isNull);
      expect(entity.commissionAmount, isNull);
    });

    test('maps REJECTED status to cancelled', () {
      final model = CommissionHistoryItemModel.fromJson({
        'id': 'rejected-1',
        'clientId': 'client-1',
        'commissionValue': '5',
        'commissionType': 'PERCENTAGE',
        'commissionAmount': 1.16,
        'status': 'REJECTED',
        'paidAt': null,
        'createdAt': '2026-06-25T12:22:46.546Z',
      });

      expect(model.toEntity().status, CommissionStatus.cancelled);
    });

    test('maps FAILED and UPCOMING statuses and photo/offering fields', () {
      final failed = CommissionHistoryItemModel.fromJson({
        'id': 'failed-1',
        'type': 'COMMISSION',
        'clientId': 'client-1',
        'clientName': 'Jane',
        'clientProfilePreviewLink': 'https://cdn.example/photo.jpg',
        'offeringName': 'Family Plan',
        'commissionType': 'PERCENTAGE',
        'commissionAmount': 0,
        'salesAmount': 99,
        'status': 'FAILED',
        'transactionId': 'tx-1',
        'createdAt': '2026-06-25T12:22:46.546Z',
      }).toEntity();

      expect(failed.status, CommissionStatus.failed);
      expect(failed.apiStatus, 'FAILED');
      expect(failed.paymentFailed, isTrue);
      expect(failed.canRecoverPayment, isTrue);
      expect(failed.clientPhotoUrl, 'https://cdn.example/photo.jpg');
      expect(failed.offeringName, 'Family Plan');
      expect(failed.itemType, 'COMMISSION');

      final upcoming = CommissionHistoryItemModel.fromJson({
        'id': 'upcoming-1',
        'type': 'UPCOMING',
        'clientId': 'client-2',
        'commissionType': 'PERCENTAGE',
        'status': 'UPCOMING',
        'salesAmount': 120,
        'createdAt': '2026-06-25T12:22:46.546Z',
      }).toEntity();

      expect(upcoming.status, CommissionStatus.upcoming);
      expect(upcoming.paymentFailed, isFalse);
      expect(upcoming.itemType, 'UPCOMING');
    });
  });
}
