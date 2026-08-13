/// User fields returned by `PATCH /users/:id` after a self-service profile update.
class UpdatedAccountUser {
  const UpdatedAccountUser({
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
}
