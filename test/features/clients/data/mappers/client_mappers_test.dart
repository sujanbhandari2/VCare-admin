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
import 'package:vcare_admin/features/clients/domain/entities/clients_list_request.dart';

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

    test('ClientListItemModel maps GROUP list payload', () {
      final entity = ClientListItemModel.fromJson({
        'id': 'group-1',
        'clientType': 'GROUP',
        'companyName': 'Acme Health LLC',
        'name': {
          'companyName': 'Acme Health LLC',
          'contactFirstName': 'Jane',
          'contactLastName': 'Doe',
        },
        'contact': {
          'email': 'billing@acmehealth.com',
          'cellPhone': '+15551234567',
        },
        'address': {
          'city': 'Austin',
          'state': 'TX',
        },
      }).toEntity();

      expect(entity.id, 'group-1');
      expect(entity.fullName, 'Acme Health LLC');
      expect(entity.email, 'billing@acmehealth.com');
      expect(entity.phone, '+15551234567');
      expect(entity.location, 'Austin, TX');
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
      expect(entity.clientType, ClientListType.individual);
    });

    test('ClientDetailModel maps web individual payload', () {
      final entity = ClientDetailModel.fromJson({
        'id': 'ind-1',
        'clientType': 'INDIVIDUAL',
        'status': 'ACTIVE',
        'basicInfo': {
          'firstName': 'Jane',
          'lastName': 'Doe',
          'dateOfBirth': '1990-01-02',
          'gender': 'FEMALE',
          'ssnLast4': '1234',
        },
        'contactInfo': {
          'email': 'jane@example.com',
          'cellPhone': '+15550001111',
          'allowTextNotification': true,
        },
        'address': {'city': 'Austin', 'state': 'TX'},
      }).toEntity();

      expect(entity.id, 'ind-1');
      expect(entity.fullName, 'Jane Doe');
      expect(entity.email, 'jane@example.com');
      expect(entity.phone, '+15550001111');
      expect(entity.gender, ClientGender.female);
      expect(entity.clientType, ClientListType.individual);
    });

    test('ClientDetailModel maps group payload', () {
      final entity = ClientDetailModel.fromJson({
        'id': 'group-1',
        'clientType': 'GROUP',
        'companyName': 'Acme Health LLC',
        'contactFirstName': 'Jane',
        'contactLastName': 'Doe',
        'email': 'billing@acmehealth.com',
        'phone': '+15551234567',
        'status': 'ACTIVE',
        'address': {'city': 'Austin', 'state': 'TX'},
      }).toEntity();

      expect(entity.id, 'group-1');
      expect(entity.fullName, 'Acme Health LLC');
      expect(entity.email, 'billing@acmehealth.com');
      expect(entity.phone, '+15551234567');
      expect(entity.clientType, ClientListType.group);
    });

    test('ClientDetailModel maps embedded affiliate agents', () {
      final entity = ClientDetailModel.fromJson({
        'id': 'ind-1',
        'clientType': 'INDIVIDUAL',
        'basicInfo': {'firstName': 'Jane', 'lastName': 'Doe'},
        'contactInfo': {'email': 'jane@example.com'},
        'affiliateAgents': [
          {
            'id': 'agent-1',
            'agentType': 'INDIVIDUAL',
            'agentCode': 'AG-100',
            'name': {'firstName': 'Sam', 'lastName': 'Rivera'},
            'contact': {
              'email': 'sam@example.com',
              'phoneNumber': '+15552223333',
            },
          },
          {
            'id': 'agent-2',
            'agentType': 'AGENCY_GROUP',
            'agencyGroup': {'name': 'Northwind Agency'},
            'name': {'firstName': 'Ada', 'lastName': 'Lopez'},
          },
          {'agentCode': 'AG-404'},
        ],
      }).toEntity();

      expect(entity.affiliateAgents, hasLength(2));

      final individual = entity.affiliateAgents.first;
      expect(individual.name, 'Sam Rivera');
      expect(individual.roleLabel, 'Agent · AG-100');
      expect(individual.email, 'sam@example.com');
      expect(individual.phone, '+15552223333');

      final agencyAgent = entity.affiliateAgents.last;
      expect(agencyAgent.roleLabel, 'Northwind Agency');
      expect(agencyAgent.email, isNull);
      expect(agencyAgent.phone, isNull);
    });

    test('ClientDetailModel defaults affiliate agents to empty', () {
      final entity = ClientDetailModel.fromJson({
        'id': 'ind-2',
        'clientType': 'INDIVIDUAL',
        'basicInfo': {'firstName': 'Jane', 'lastName': 'Doe'},
        'contactInfo': {'email': 'jane@example.com'},
      }).toEntity();

      expect(entity.affiliateAgents, isEmpty);
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

    test('ClientCaseModel prefers title over type in create payload', () {
      final entity = ClientCaseModel.fromJson({
        'id': 'f6a7665d-3c1b-4f8f-9d54-553fe2d8f157',
        'status': 'REQUESTED',
        'title': 'Referral assistance needed',
        'createdAt': '2026-06-25T11:29:06.803Z',
        'updatedAt': '2026-06-25T11:29:06.803Z',
      }).toEntity();

      expect(entity.title, 'Referral assistance needed');
      expect(entity.status, ClientCaseStatus.requested);
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
