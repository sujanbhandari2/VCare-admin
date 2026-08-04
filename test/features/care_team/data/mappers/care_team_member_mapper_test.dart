import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/care_team/data/mappers/care_team_member_mapper.dart';
import 'package:vcare_admin/features/care_team/data/models/care_team_member_model.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';

void main() {
  test('maps profilePreviewLink to photoUrl and preserves role title', () {
    const model = CareTeamMemberModel(
      id: 'c98f9493-75e0-4dd1-81df-619474945dd4',
      name: 'Dr. Jane Smith',
      role: 'Primary Care Physician',
      phone: '9862167322',
      email: 'jane@example.com',
      website: 'https://clinic.example.com',
      notes: 'Preferred contact mornings',
      address: '123 Main St',
      policy: 'POL-123',
      group: 'Internal Medicine',
      profilePreviewLink: 'https://cdn.example.com/jane.jpg',
      profileId: 'profile-1',
      userId: 'user-1',
      agentId: 'agent-1',
    );

    final entity = model.toEntity();

    expect(entity.id, model.id);
    expect(entity.name, 'Dr. Jane Smith');
    expect(entity.role, CareTeamRole.provider);
    expect(entity.roleTitle, 'Primary Care Physician');
    expect(entity.roleLabel, 'Primary Care Physician');
    expect(entity.photoUrl, 'https://cdn.example.com/jane.jpg');
    expect(entity.bio, 'Preferred contact mornings');
    expect(entity.policyNumber, 'POL-123');
    expect(entity.groupNumber, 'Internal Medicine');
    expect(entity.profileId, 'profile-1');
    expect(entity.userId, 'user-1');
    expect(entity.agentId, 'agent-1');
    expect(entity.isAgentOwned, isTrue);
    expect(entity.canMessage, isTrue);
  });

  test('falls back to nested user and profileFile url', () {
    final model = CareTeamMemberModel.fromJson({
      'id': '1',
      'name': 'Support Desk',
      'role': 'Customer Support',
      'user': {'id': 'nested-user', 'email': 'support@example.com'},
      'profileFile': {'id': 'f1', 'name': 'a.jpg', 'url': 'https://cdn/a.jpg'},
    });

    final entity = model.toEntity();
    expect(entity.role, CareTeamRole.customerSupport);
    expect(entity.userId, 'nested-user');
    expect(entity.email, 'support@example.com');
    expect(entity.photoUrl, 'https://cdn/a.jpg');
    expect(entity.isAgentOwned, isFalse);
  });

  test('treats blank profilePreviewLink as missing photo', () {
    const model = CareTeamMemberModel(
      id: '1',
      name: 'Dr. Sujan Bhandari',
      role: 'Primary Care Physician',
      profilePreviewLink: '   ',
    );

    expect(model.toEntity().photoUrl, isNull);
  });

  test('mapCareTeamRole recognizes Customer Support and Agent', () {
    expect(mapCareTeamRole('Customer Support'), CareTeamRole.customerSupport);
    expect(mapCareTeamRole('Agent'), CareTeamRole.agent);
    expect(mapCareTeamRole('Advocate'), CareTeamRole.advocate);
  });

  test('buildCareTeamCreatePayload omits empty optionals and maps profileId', () {
    final payload = buildCareTeamCreatePayload(
      role: 'Provider',
      name: 'Dr. Sujan Bhandari',
      phone: '9862167322',
      email: 'jane@example.com',
      website: 'https://clinic.example.com',
      notes: 'Preferred contact mornings',
      address: '',
      policy: null,
      group: 'Internal Medicine',
      profileId: '11111111-1111-1111-1111-111111111111',
    );

    expect(payload, {
      'role': 'Provider',
      'name': 'Dr. Sujan Bhandari',
      'phone': '9862167322',
      'email': 'jane@example.com',
      'website': 'https://clinic.example.com',
      'notes': 'Preferred contact mornings',
      'group': 'Internal Medicine',
      'profileId': '11111111-1111-1111-1111-111111111111',
    });
    expect(payload.containsKey('address'), isFalse);
    expect(payload.containsKey('policy'), isFalse);
  });

  test('buildCareTeamUpdatePayload nulls empty fields and can clear profileId',
      () {
    final payload = buildCareTeamUpdatePayload(
      role: 'Provider',
      name: 'Dr. Jane',
      phone: '',
      email: 'jane@example.com',
      website: null,
      notes: 'Notes',
      address: null,
      policy: null,
      group: null,
      profileId: null,
      setProfileId: true,
    );

    expect(payload['phone'], isNull);
    expect(payload['email'], 'jane@example.com');
    expect(payload['website'], isNull);
    expect(payload['notes'], 'Notes');
    expect(payload.containsKey('profileId'), isTrue);
    expect(payload['profileId'], isNull);
  });

  test('buildCareTeamUpdatePayload omits profileId when not set', () {
    final payload = buildCareTeamUpdatePayload(
      role: 'Agent',
      name: 'Alex',
      setProfileId: false,
    );
    expect(payload.containsKey('profileId'), isFalse);
  });
}
