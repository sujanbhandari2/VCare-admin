import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/clients/data/mappers/client_case_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_detail_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_document_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_list_item_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_membership_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_payment_method_mapper.dart';
import 'package:vcare_admin/features/clients/data/mappers/client_transaction_mapper.dart';
import 'package:vcare_admin/features/clients/data/models/client_case_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_detail_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_document_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_list_item_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_membership_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_payment_method_model.dart';
import 'package:vcare_admin/features/clients/data/models/client_transaction_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

void main() {
  group('Client mappers', () {
    test('ClientListItemModel maps list payload', () {
      final entity = ClientListItemModel.fromJson({
        'id': 'ca0cf27a-e98c-4d77-b09e-a413c553067f',
        'clientType': 'INDIVIDUAL',
        'name': {
          'firstName': 'Aspen',
          'middleName': 'Kristen Tillman',
          'lastName': 'Michael',
        },
        'contact': {
          'email': 'arjun+vakitaha@vitafyhealth.com',
          'phoneNumber': '+11183586705',
        },
        'address': {
          'city': 'Et ut sed provident',
          'state': 'Id impedit id quo',
        },
      }).toEntity();

      expect(entity.id, 'ca0cf27a-e98c-4d77-b09e-a413c553067f');
      expect(entity.fullName, 'Aspen Kristen Tillman Michael');
      expect(entity.email, 'arjun+vakitaha@vitafyhealth.com');
      expect(entity.location, 'Et ut sed provident, Id impedit id quo');
    });

    test('ClientDetailModel maps detail payload', () {
      final entity = ClientDetailModel.fromJson({
        'profile': {
          'id': 'ca0cf27a-e98c-4d77-b09e-a413c553067f',
          'firstName': 'Aspen',
          'middleName': 'Kristen Tillman',
          'lastName': 'Michael',
          'dateOfBirth': '2026-06-03T00:00:00.000Z',
          'gender': 'MALE',
          'status': 'INACTIVE',
          'ssnLast4': '2342',
          'address': {
            'city': 'Et ut sed provident',
            'state': 'Id impedit id quo',
          },
        },
        'contact': {
          'email': 'arjun+vakitaha@vitafyhealth.com',
          'phoneNumber': '+11183586705',
          'allowTextNotification': false,
        },
        'memberCard': {
          'cardLast4': null,
          'cardBrand': null,
        },
      }).toEntity();

      expect(entity.fullName, 'Aspen Kristen Tillman Michael');
      expect(entity.gender, ClientGender.male);
      expect(entity.ssn, '***-**-2342');
      expect(entity.allowTextNotification, isFalse);
    });

    test('ClientMembershipsResultModel maps memberships payload', () {
      final entity = ClientMembershipsResultModel.fromJson({
        'clientId': 'ca0cf27a-e98c-4d77-b09e-a413c553067f',
        'details': [
          {
            'id': '7e9c7877-7d04-43ed-a4b7-bf67e9d51cf3',
            'clientId': 'ca0cf27a-e98c-4d77-b09e-a413c553067f',
            'enrollmentType': 'PRIMARY',
            'enrollmentDisplayLabel': 'Primary',
            'status': 'APPROVED',
            'startDate': '2026-06-25T00:00:00.000Z',
            'offeringDetails': {
              'offeringName': 'asdf',
              'description': 'safawsf',
              'billingInterval': 'MONTHLY',
              'fee': '111',
            },
          },
        ],
        'totalGroup': 1,
      }).toEntity();

      expect(entity.memberships, hasLength(1));
      expect(entity.memberships.first.plan, 'asdf');
      expect(entity.memberships.first.status, ClientMembershipStatus.approved);
      expect(entity.memberships.first.cost, 111);
    });

    test('ClientPaymentMethodModel maps payment method payload', () {
      final entity = ClientPaymentMethodModel.fromJson({
        'id': 'c3862459-e703-44b0-a974-832cb6800597',
        'type': 'CASH',
        'isPrimary': true,
        'isActive': true,
      }).toEntity();

      expect(entity.type, ClientPaymentMethodType.cash);
      expect(entity.isPrimary, isTrue);
      expect(entity.label, 'Cash');
    });

    test('ClientTransactionModel maps transaction payload', () {
      final entity = ClientTransactionModel.fromJson({
        'id': '6476fa89-3ba8-4148-9f0a-7d460b25caa1',
        'type': 'ENROLLMENT_SUBSCRIPTION',
        'status': 'PENDING',
        'amount': '112',
        'invoiceNumber': 'INV-1B4B5118-20260625-X9MMGN',
        'transactionDate': '2026-06-25T00:00:00.000Z',
        'billingStartDate': '2026-06-25',
        'billingEndDate': '2026-07-24',
        'payer': {
          'name': 'Aspen Kristen Tillman Michael',
          'email': 'arjun+vakitaha@vitafyhealth.com',
        },
      }).toEntity();

      expect(entity.amount, 112);
      expect(entity.status, ClientTransactionStatus.pending);
      expect(entity.reference, 'INV-1B4B5118-20260625-X9MMGN');
      expect(entity.membershipTitle, 'Enrollment Subscription');
    });

    test('ClientCaseModel maps case payload', () {
      final entity = ClientCaseModel.fromJson({
        'id': '5d360977-1b3f-459d-a7e4-75bfcf74f922',
        'status': 'REQUESTED',
        'type': 'Procedure Cost',
        'createdAt': '2026-06-25T05:58:27.500Z',
        'updatedAt': '2026-06-25T05:58:27.500Z',
      }).toEntity();

      expect(entity.id, '5d360977-1b3f-459d-a7e4-75bfcf74f922');
      expect(entity.caseId, '5D360977');
      expect(entity.title, 'Procedure Cost');
      expect(entity.status, ClientCaseStatus.requested);
      expect(entity.createdAt, '2026-06-25T05:58:27.500Z');
    });

    test('ClientDocumentModel maps document payload', () {
      const hostBaseUrl = 'https://dev-api-v4.vitafyhealth.com/';
      final entity = ClientDocumentModel.fromJson({
        'id': 'fbe1696e-2f2b-45af-9467-d31026a69dba',
        'name': 'pexels-gamze-altinsoy-157458220-11123835.jpg',
        'url': 'test/pexels-gamze-altinsoy-157458220-11123835.jpg',
        'createdAt': '2026-06-25T06:15:24.432Z',
      }).toEntity(hostBaseUrl: hostBaseUrl);

      expect(entity.id, 'fbe1696e-2f2b-45af-9467-d31026a69dba');
      expect(entity.name, 'pexels-gamze-altinsoy-157458220-11123835.jpg');
      expect(
        entity.url,
        'https://dev-api-v4.vitafyhealth.com/api/test/pexels-gamze-altinsoy-157458220-11123835.jpg',
      );
      expect(entity.mime, 'image/jpeg');
      expect(entity.size, '—');
      expect(entity.uploadedAt, '2026-06-25T06:15:24.432Z');
    });
  });
}
