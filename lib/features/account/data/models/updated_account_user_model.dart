class UpdatedAccountUserModel {
  const UpdatedAccountUserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileId,
    this.profilePreviewLink,
    this.profileImage,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileId;
  final String? profilePreviewLink;
  final String? profileImage;

  factory UpdatedAccountUserModel.fromJson(Map<String, dynamic> json) {
    return UpdatedAccountUserModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profileId: json['profileId']?.toString(),
      profilePreviewLink: json['profilePreviewLink'] as String?,
      profileImage: json['profileImage'] as String?,
    );
  }
}
