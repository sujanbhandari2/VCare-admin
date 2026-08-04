import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_utils.dart';

void main() {
  group('splitCareTeamMembers', () {
    test('splits listed vs agent-owned by agentId', () {
      const listed = CareTeamMember(
        id: '1',
        name: 'Org Contact',
        role: CareTeamRole.advocate,
      );
      const agentOwned = CareTeamMember(
        id: '2',
        name: 'My Contact',
        role: CareTeamRole.provider,
        agentId: 'agent-9',
      );
      const blankAgent = CareTeamMember(
        id: '3',
        name: 'Blank',
        role: CareTeamRole.agent,
        agentId: '   ',
      );

      final split = splitCareTeamMembers([listed, agentOwned, blankAgent]);

      expect(split.listedTeam.map((m) => m.id), ['1', '3']);
      expect(split.agentTeam.map((m) => m.id), ['2']);
    });
  });

  test('careTeamRoleLabel includes Customer Support', () {
    expect(
      careTeamRoleLabel(CareTeamRole.customerSupport),
      'Customer Support',
    );
  });

  test('cardRoleLabel uses Your advocate for Advocate', () {
    const member = CareTeamMember(
      id: '1',
      name: 'Ada',
      role: CareTeamRole.advocate,
      roleTitle: 'Advocate',
    );
    expect(member.cardRoleLabel, 'Your advocate');
  });
}
