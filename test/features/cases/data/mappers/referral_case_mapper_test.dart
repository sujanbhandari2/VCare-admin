import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/cases/data/mappers/referral_case_mapper.dart';
import 'package:vcare_admin/features/cases/data/models/referral_case_model.dart';

void main() {
  group('ReferralCaseModelMapper', () {
    test('maps list record into domain entity', () {
      final model = ReferralCaseModel.fromJson({
        'id': 'abcdef12-3456-7890-abcd-ef1234567890',
        'tenantId': 'tenant-1',
        'status': 'IN_PROGRESS',
        'type': 'Care Coordination',
        'priority': 'HIGH',
        'assignedTo': 'user-1',
        'clientId': 'client-1',
        'sponsorId': null,
        'sponsorType': null,
        'createdAt': '2026-01-15T10:00:00Z',
        'updatedAt': '2026-01-16T10:00:00Z',
        'createdBy': {'id': 'creator-1', 'fullName': 'Admin User'},
        'updatedBy': 'creator-1',
        'isBookmarked': true,
        'assignee': {'id': 'user-1', 'fullName': 'Casey Advocate'},
        'client': {
          'id': 'client-1',
          'clientType': 'INDIVIDUAL',
          'name': {
            'firstName': 'Alice',
            'lastName': 'Nguyen',
          },
          'contact': {
            'email': 'alice@example.com',
            'phoneNumber': '5551234567',
          },
          'dateOfBirth': '1990-05-01',
        },
      });

      final entity = model.toEntity();

      expect(entity.id, 'abcdef12-3456-7890-abcd-ef1234567890');
      expect(entity.caseNumber, 'ABCDEF12');
      expect(entity.status, isNotNull);
      expect(entity.status.apiValue, 'IN_PROGRESS');
      expect(entity.priority.apiValue, 'HIGH');
      expect(entity.caseType, 'Care Coordination');
      expect(entity.assignedTo, 'Casey Advocate');
      expect(entity.assignedToId, 'user-1');
      expect(entity.isBookmarked, isTrue);
      expect(entity.client.firstName, 'Alice');
      expect(entity.client.lastName, 'Nguyen');
      expect(entity.client.email, 'alice@example.com');
      expect(entity.createdBy, 'Admin User');
      expect(entity.createdById, 'creator-1');
    });

    test('falls back to contact first/last name when name object is missing', () {
      final model = ReferralCaseModel.fromJson({
        'id': 'case-2',
        'clientId': 'client-2',
        'status': 'NEW',
        'type': 'Provider Search',
        'priority': 'MEDIUM',
        'createdAt': '2026-01-15T10:00:00Z',
        'client': {
          'id': 'client-2',
          'clientType': 'INDIVIDUAL',
          'contact': {
            'firstName': 'Sam',
            'lastName': 'Lee',
            'email': 'sam@example.com',
            'phoneNumber': '5550001111',
          },
        },
      });

      final entity = model.toEntity();
      expect(entity.client.firstName, 'Sam');
      expect(entity.client.lastName, 'Lee');
      expect(entity.client.email, 'sam@example.com');
      expect(entity.client.initials, 'SL');
    });
  });
}
