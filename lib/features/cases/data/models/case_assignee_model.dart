/// Associated user record used as a case assignee.
class CaseAssigneeModel {
  const CaseAssigneeModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.profileImage,
    this.profilePreviewLink,
    this.displayName,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? profileImage;
  final String? profilePreviewLink;
  final String? displayName;

  factory CaseAssigneeModel.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    String? role = _optionalString(json['role']);
    if ((role == null || role.isEmpty) && roles is List && roles.isNotEmpty) {
      role = _optionalString(roles.first);
    }

    return CaseAssigneeModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: _optionalString(json['firstName']),
      lastName: _optionalString(json['lastName']),
      role: role,
      profileImage: _optionalString(json['profileImage']),
      profilePreviewLink: _optionalString(json['profilePreviewLink']),
      displayName: _optionalString(json['displayName'] ?? json['fullName']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
