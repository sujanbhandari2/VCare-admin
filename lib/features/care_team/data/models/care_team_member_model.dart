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
    this.profileId,
    this.userId,
    this.agentId,
    this.profileFileUrl,
    this.userEmail,
    this.userNestedId,
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
  final String? profileId;
  final String? userId;
  final String? agentId;
  final String? profileFileUrl;
  final String? userEmail;
  final String? userNestedId;

  factory CareTeamMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    Map<String, dynamic>? userMap;
    if (user is Map) {
      userMap = Map<String, dynamic>.from(user);
    }

    final profileFile = json['profileFile'];
    String? profileFileUrl;
    if (profileFile is Map) {
      profileFileUrl = profileFile['url']?.toString();
    }

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
      profileId: json['profileId']?.toString(),
      userId: json['userId']?.toString(),
      agentId: json['agentId']?.toString(),
      profileFileUrl: profileFileUrl,
      userEmail: userMap?['email']?.toString(),
      userNestedId: userMap?['id']?.toString(),
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
