class AssociatedUser {
  const AssociatedUser({
    required this.id,
    required this.email,
    this.firstName,
    this.middleName,
    this.lastName,
    this.profileImage,
    this.profilePreviewLink,
    required this.userType,
    required this.role,
    required this.status,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? profileImage;
  final String? profilePreviewLink;
  final String userType;
  final String role;
  final String status;

  String get displayName {
    final parts = <String?>[
      firstName,
      middleName,
      lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    final trimmedEmail = email.trim();
    return trimmedEmail.isNotEmpty ? trimmedEmail : id;
  }

  /// Prefer [profilePreviewLink] over legacy [profileImage] for display URLs.
  String? get profilePhotoUrl {
    final preview = profilePreviewLink?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview;
    }
    final image = profileImage?.trim();
    if (image != null && image.isNotEmpty) {
      return image;
    }
    return null;
  }

  bool get isPlatformUser => userType.toUpperCase() == 'PLATFORM_USER';
}
