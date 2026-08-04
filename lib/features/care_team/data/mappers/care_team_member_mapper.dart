import 'package:vcare_admin/features/care_team/data/models/care_team_member_model.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';

extension CareTeamMemberModelMapper on CareTeamMemberModel {
  CareTeamMember toEntity() {
    final preview = profilePreviewLink?.trim();
    final fileUrl = profileFileUrl?.trim();
    final photo = (preview != null && preview.isNotEmpty)
        ? preview
        : (fileUrl != null && fileUrl.isNotEmpty ? fileUrl : null);

    final resolvedEmail = email?.trim().isNotEmpty == true
        ? email!.trim()
        : (userEmail?.trim().isNotEmpty == true ? userEmail!.trim() : null);

    final resolvedUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : (userNestedId?.trim().isNotEmpty == true
            ? userNestedId!.trim()
            : null);

    final resolvedAgentId =
        agentId?.trim().isNotEmpty == true ? agentId!.trim() : null;
    final resolvedProfileId =
        profileId?.trim().isNotEmpty == true ? profileId!.trim() : null;

    return CareTeamMember(
      id: id,
      name: name.trim().isNotEmpty ? name.trim() : 'Unnamed contact',
      role: mapCareTeamRole(role),
      roleTitle: role?.trim().isNotEmpty == true ? role!.trim() : null,
      photoUrl: photo,
      bio: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      email: resolvedEmail,
      phone: phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      website: website?.trim().isNotEmpty == true ? website!.trim() : null,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
      policyNumber: policy?.trim().isNotEmpty == true ? policy!.trim() : null,
      groupNumber: group?.trim().isNotEmpty == true ? group!.trim() : null,
      profileId: resolvedProfileId,
      userId: resolvedUserId,
      agentId: resolvedAgentId,
    );
  }
}

CareTeamRole mapCareTeamRole(String? role) {
  final value = role?.trim() ?? '';
  if (value.isEmpty) {
    return CareTeamRole.provider;
  }

  final normalized = value.toLowerCase();
  if (normalized == 'advocate' || normalized.contains('advocate')) {
    return CareTeamRole.advocate;
  }
  if (normalized == 'customer support' ||
      normalized.contains('customer support') ||
      (normalized.contains('support') && !normalized.contains('agent'))) {
    return CareTeamRole.customerSupport;
  }
  if (RegExp(r'\bagent\b').hasMatch(normalized) || normalized == 'agent') {
    return CareTeamRole.agent;
  }
  if (normalized.contains('employer') || RegExp(r'\bhr\b').hasMatch(normalized)) {
    return CareTeamRole.employer;
  }
  if (normalized.contains('insurance')) {
    return CareTeamRole.insurance;
  }
  if (normalized.contains('provider') ||
      normalized.contains('physician') ||
      normalized.contains('doctor') ||
      RegExp(r'\bmd\b').hasMatch(normalized)) {
    return CareTeamRole.provider;
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

/// Builds a PUT body. Empty optional strings become `null` (clear on server).
///
/// When [setProfileId] is true, [profileId] is included even if null (photo clear).
Map<String, dynamic> buildCareTeamUpdatePayload({
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
  bool setProfileId = false,
}) {
  String? nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  final payload = <String, dynamic>{
    'role': role.trim(),
    'name': name.trim(),
    'phone': nullIfEmpty(phone),
    'email': nullIfEmpty(email),
    'website': nullIfEmpty(website),
    'notes': nullIfEmpty(notes),
    'address': nullIfEmpty(address),
    'policy': nullIfEmpty(policy),
    'group': nullIfEmpty(group),
  };

  if (setProfileId) {
    final trimmed = profileId?.trim();
    payload['profileId'] = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  return payload;
}
