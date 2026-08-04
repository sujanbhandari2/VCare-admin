import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';

const careTeamRoles = CareTeamRole.values;

bool isCareTeamAgentOwned(CareTeamMember member) => member.isAgentOwned;

bool isCareTeamOrgRole(CareTeamRole role) =>
    role == CareTeamRole.employer || role == CareTeamRole.insurance;

String careTeamRoleLabel(CareTeamRole role) {
  switch (role) {
    case CareTeamRole.advocate:
      return 'Advocate';
    case CareTeamRole.agent:
      return 'Agent';
    case CareTeamRole.customerSupport:
      return 'Customer Support';
    case CareTeamRole.provider:
      return 'Provider';
    case CareTeamRole.employer:
      return 'Employer';
    case CareTeamRole.insurance:
      return 'Insurance';
  }
}

CareTeamRole? careTeamRoleFromLabel(String label) {
  for (final role in careTeamRoles) {
    if (careTeamRoleLabel(role) == label) {
      return role;
    }
  }
  return null;
}

String careTeamInitials(String name) {
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

({List<CareTeamMember> listedTeam, List<CareTeamMember> agentTeam})
    splitCareTeamMembers(List<CareTeamMember> team) {
  final listed = <CareTeamMember>[];
  final agent = <CareTeamMember>[];
  for (final member in team) {
    if (member.isAgentOwned) {
      agent.add(member);
    } else {
      listed.add(member);
    }
  }
  return (listedTeam: listed, agentTeam: agent);
}
