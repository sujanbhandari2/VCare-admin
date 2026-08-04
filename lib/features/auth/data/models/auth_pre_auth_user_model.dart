class AuthPreAuthUserModel {
  const AuthPreAuthUserModel({
    this.firstName,
    this.middleName,
    this.lastName,
    this.dob,
    this.zipCode,
    this.email,
    this.phone,
    this.gender,
    this.primaryCity,
    this.primaryState,
  });

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dob;
  final String? zipCode;
  final String? email;
  final String? phone;
  final String? gender;
  final String? primaryCity;
  final String? primaryState;

  factory AuthPreAuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthPreAuthUserModel(
      firstName: _nonEmptyString(json['firstName']),
      middleName: _nonEmptyString(json['middleName']),
      lastName: _nonEmptyString(json['lastName']),
      dob: _nonEmptyString(json['dob']),
      zipCode: _nonEmptyString(json['zipCode']),
      email: _nonEmptyString(json['email']),
      phone: _nonEmptyString(json['phone']),
      gender: _nonEmptyString(json['gender']),
      primaryCity: _nonEmptyString(json['primaryCity']),
      primaryState: _nonEmptyString(json['primaryState']),
    );
  }

  static String? _nonEmptyString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
