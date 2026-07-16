import 'package:vcare_admin/features/care_team/data/models/care_team_member_model.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';

extension CareTeamMemberModelMapper on CareTeamMemberModel {
  CareTeamMember toEntity() {
    final preview = profilePreviewLink?.trim();

    return CareTeamMember(
      id: id,
      name: name.trim().isNotEmpty ? name.trim() : 'Unnamed contact',
      role: mapCareTeamRole(role),
      roleTitle: role?.trim().isNotEmpty == true ? role!.trim() : null,
      photoUrl: preview != null && preview.isNotEmpty ? preview : null,
      bio: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      email: email?.trim().isNotEmpty == true ? email!.trim() : null,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      website: website?.trim().isNotEmpty == true ? website!.trim() : null,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
      policyNumber: policy?.trim().isNotEmpty == true ? policy!.trim() : null,
      groupNumber: group?.trim().isNotEmpty == true ? group!.trim() : null,
    );
  }
}

CareTeamRole mapCareTeamRole(String? role) {
  final normalized = role?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return CareTeamRole.provider;
  }
  if (normalized.contains('advocate')) {
    return CareTeamRole.advocate;
  }
  if (normalized.contains('agent')) {
    return CareTeamRole.agent;
  }
  if (normalized.contains('employer')) {
    return CareTeamRole.employer;
  }
  if (normalized.contains('insurance')) {
    return CareTeamRole.insurance;
  }
  return CareTeamRole.provider;
}

Map<String, dynamic> buildCareTeamCreatePayload({
  required String role,
  required String name,
  String? phone,
  String? email,
  String? website,
  String? notes,
  String? address,
  String? policy,
  String? group,
  String? profileId,
}) {
  void putIfPresent(Map<String, dynamic> target, String key, String? value) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      target[key] = trimmed;
    }
  }

  final payload = <String, dynamic>{
    'role': role.trim(),
    'name': name.trim(),
  };

  putIfPresent(payload, 'phone', phone);
  putIfPresent(payload, 'email', email);
  putIfPresent(payload, 'website', website);
  putIfPresent(payload, 'notes', notes);
  putIfPresent(payload, 'address', address);
  putIfPresent(payload, 'policy', policy);
  putIfPresent(payload, 'group', group);
  putIfPresent(payload, 'profileId', profileId);

  return payload;
}
