import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/data/mappers/family_member_mapper.dart';
import 'package:vcare_admin/features/profile/data/models/family_member_model.dart';

void main() {
  group('FamilyMemberMapper', () {
    test('toEntity maps model fields', () {
      const model = FamilyMemberModel(
        id: 'member-1',
        fullName: 'Jane Doe',
        relationship: 'Spouse',
        dateOfBirth: '1990-05-15',
        gender: 'FEMALE',
        profilePreviewLink: 'https://example.com/photo.jpg',
      );

      final entity = model.toEntity();

      expect(entity.id, 'member-1');
      expect(entity.fullName, 'Jane Doe');
      expect(entity.relationship, 'Spouse');
      expect(entity.dateOfBirth, '1990-05-15');
      expect(entity.gender, 'FEMALE');
      expect(entity.photoUrl, 'https://example.com/photo.jpg');
    });

    test('toFamilyMemberPayload maps form fields', () {
      final payload = toFamilyMemberPayload(
        fullName: 'ramila s Doe',
        relationship: 'Spouse',
        gender: 'FEMALE',
        dateOfBirth: '1990-05-15',
      );

      expect(payload, {
        'fullName': 'ramila s Doe',
        'relationship': 'Spouse',
        'gender': 'FEMALE',
        'dateOfBirth': '1990-05-15',
      });
    });

    test('toFamilyMemberPayload includes profileId when present', () {
      final payload = toFamilyMemberPayload(
        fullName: 'Jane Doe',
        relationship: 'Spouse',
        gender: 'FEMALE',
        dateOfBirth: '1990-05-15',
        profileId: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
      );

      expect(payload['profileId'], '3fa85f64-5717-4562-b3fc-2c963f66afa6');
    });

    test('toProfileFamilyMember maps entity to presentation model', () {
      final profileMember = const FamilyMemberModel(
        id: 'member-1',
        fullName: 'Jane Doe',
        relationship: 'Spouse',
        dateOfBirth: '1990-05-15',
        gender: 'FEMALE',
      ).toEntity().toProfileFamilyMember();

      expect(profileMember.id, 'member-1');
      expect(profileMember.name, 'Jane Doe');
      expect(profileMember.relationship, 'Spouse');
      expect(profileMember.dob, '1990-05-15');
      expect(profileMember.gender, 'FEMALE');
    });
  });
}
