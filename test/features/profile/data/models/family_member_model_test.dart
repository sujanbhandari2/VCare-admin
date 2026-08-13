import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/data/models/family_member_model.dart';

void main() {
  group('FamilyMemberModel', () {
    test('fromJson maps API fields', () {
      final model = FamilyMemberModel.fromJson({
        'id': 'd53b0357-c372-40e4-8329-f2b40a166545',
        'tenantId': '1b4b5118-055f-44e7-9ddd-59e5e357e756',
        'fullName': 'Jane Doe',
        'relationship': 'Spouse',
        'gender': 'FEMALE',
        'dateOfBirth': '1990-05-15',
        'profilePreviewLink': 'https://example.com/photo.jpg',
      });

      expect(model.id, 'd53b0357-c372-40e4-8329-f2b40a166545');
      expect(model.fullName, 'Jane Doe');
      expect(model.relationship, 'Spouse');
      expect(model.gender, 'FEMALE');
      expect(model.dateOfBirth, '1990-05-15');
      expect(model.profilePreviewLink, 'https://example.com/photo.jpg');
    });

    test('parseFamilyMemberList filters invalid entries', () {
      final models = parseFamilyMemberList([
        {
          'id': 'member-1',
          'fullName': 'Jane Doe',
          'relationship': 'Spouse',
          'dateOfBirth': '1990-05-15',
        },
        {'fullName': 'Missing id'},
      ]);

      expect(models, hasLength(1));
      expect(models.first.id, 'member-1');
    });
  });
}
