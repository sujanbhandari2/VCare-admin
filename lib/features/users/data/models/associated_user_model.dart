/// User record from `GET users` and `GET users/associated`.
///
/// Names arrive flat on most payloads but can also be nested under `profile`,
/// `name`, or collapsed into `fullName`, so all of those are read here — this
/// mirrors the web `normalizeUserRecord`.
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
    final profile = _optionalMap(json['profile']);
    final nestedName = _optionalMap(json['name']);

    var firstName = _optionalString(json['firstName']) ??
        _optionalString(profile?['firstName']) ??
        _optionalString(nestedName?['firstName']);
    var lastName = _optionalString(json['lastName']) ??
        _optionalString(profile?['lastName']) ??
        _optionalString(nestedName?['lastName']);

    if (firstName == null && lastName == null) {
      final fullName = _optionalString(json['fullName']) ??
          _optionalString(profile?['fullName']) ??
          _optionalString(nestedName?['fullName']) ??
          (json['name'] is String ? _optionalString(json['name']) : null);
      final parts = fullName?.split(RegExp(r'\s+')) ?? const <String>[];
      if (parts.isNotEmpty) {
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
      }
    }

    final roles = json['roles'];

    return AssociatedUserModel(
      id: json['id']?.toString() ?? '',
      email:
          _optionalString(json['email']) ??
          _optionalString(profile?['email']) ??
          '',
      firstName: firstName,
      middleName: _optionalString(json['middleName']) ??
          _optionalString(profile?['middleName']) ??
          _optionalString(nestedName?['middleName']),
      lastName: lastName,
      profileImage: _optionalString(json['profileImage']),
      profilePreviewLink: _optionalString(json['profilePreviewLink']) ??
          _optionalString(_optionalMap(json['profileFile'])?['url']),
      userType: json['userType']?.toString() ?? '',
      role: _optionalString(json['role']) ??
          (roles is List && roles.isNotEmpty
              ? _optionalString(roles.first) ?? ''
              : ''),
      status: json['status']?.toString() ?? '',
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map<String, dynamic> && data['data'] is List;
  }
}

Map<String, dynamic>? _optionalMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _optionalString(dynamic value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
