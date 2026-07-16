import 'package:vcare_admin/features/home/data/home_models.dart';

const careTeamRoles = CareTeamRole.values;

const _systemContactIds = <String>{
  'ct1',
  'ct2',
  'ct4',
  'ct6',
  'ct7',
  'ct8',
  'ct9',
  'ct10',
  'ct11',
  'ct12',
  'ct13',
  'ct14',
};

/// ct5 (BlueShield National) is intentionally editable for testing.
bool isCareTeamSystemContact(String id) => _systemContactIds.contains(id);

bool isCareTeamOrgRole(CareTeamRole role) =>
    role == CareTeamRole.employer || role == CareTeamRole.insurance;

String careTeamRoleLabel(CareTeamRole role) {
  switch (role) {
    case CareTeamRole.advocate:
      return 'Advocate';
    case CareTeamRole.agent:
      return 'Agent';
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
