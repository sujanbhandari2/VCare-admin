class CareTeamMemberModel {
  const CareTeamMemberModel({
    required this.id,
    required this.name,
    this.role,
    this.phone,
    this.email,
    this.website,
    this.notes,
    this.address,
    this.policy,
    this.group,
    this.profilePreviewLink,
  });

  final String id;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String? website;
  final String? notes;
  final String? address;
  final String? policy;
  final String? group;
  final String? profilePreviewLink;

  factory CareTeamMemberModel.fromJson(Map<String, dynamic> json) {
    return CareTeamMemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      notes: json['notes']?.toString(),
      address: json['address']?.toString(),
      policy: json['policy']?.toString(),
      group: json['group']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
    );
  }
}

List<CareTeamMemberModel> parseCareTeamMemberList(dynamic data) {
  if (data is! List) {
    return const [];
  }

  return data
      .whereType<Map>()
      .map(
        (entry) => CareTeamMemberModel.fromJson(
          Map<String, dynamic>.from(entry),
        ),
      )
      .where((model) => model.id.isNotEmpty)
      .toList();
}
