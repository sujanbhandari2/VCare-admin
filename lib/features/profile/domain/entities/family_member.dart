class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.fullName,
    required this.relationship,
    required this.dateOfBirth,
    this.gender,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String relationship;
  final String dateOfBirth;
  final String? gender;
  final String? photoUrl;
}
