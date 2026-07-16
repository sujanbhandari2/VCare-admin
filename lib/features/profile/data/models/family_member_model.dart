class FamilyMemberModel {
  const FamilyMemberModel({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.dateOfBirth,
    this.gender,
    this.profilePreviewLink,
  });

  final String id;
  final String fullName;
  final String relationship;
  final String dateOfBirth;
  final String? gender;
  final String? profilePreviewLink;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      gender: json['gender']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
    );
  }
}

List<FamilyMemberModel> parseFamilyMemberList(dynamic data) {
  if (data is! List) {
    return const [];
  }

  return data
      .whereType<Map>()
      .map(
        (entry) => FamilyMemberModel.fromJson(
          Map<String, dynamic>.from(entry),
        ),
      )
      .where((model) => model.id.isNotEmpty)
      .toList();
}

FamilyMemberModel parseFamilyMemberItem(dynamic data) {
  if (data is! Map) {
    return const FamilyMemberModel(
      id: '',
      fullName: '',
      relationship: '',
      dateOfBirth: '',
    );
  }

  return FamilyMemberModel.fromJson(Map<String, dynamic>.from(data));
}
