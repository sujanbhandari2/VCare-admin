class AssociatedUserModel {
  const AssociatedUserModel({
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

  factory AssociatedUserModel.fromJson(Map<String, dynamic> json) {
    return AssociatedUserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName'] as String?,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      profileImage: _optionalString(json['profileImage']),
      profilePreviewLink: _optionalString(json['profilePreviewLink']),
      userType: json['userType']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map<String, dynamic> && data['data'] is List;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
