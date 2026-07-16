import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

/// Builds the JSON body for `PATCH auth/me`.
Map<String, dynamic> toUpdateMePayload({
  required String firstName,
  String? middleName,
  required String lastName,
  required String email,
  required String phone,
  required String dateOfBirth,
  String? gender,
  String? profileId,
  bool? allowTextNotification,
  ProfileAddress? address,
}) {
  final payload = <String, dynamic>{
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'dateOfBirth': dateOfBirth.trim(),
  };

  final trimmedMiddle = middleName?.trim();
  if (trimmedMiddle != null && trimmedMiddle.isNotEmpty) {
    payload['middleName'] = trimmedMiddle;
  }

  final trimmedGender = gender?.trim();
  if (trimmedGender != null && trimmedGender.isNotEmpty) {
    payload['gender'] = trimmedGender;
  }

  final trimmedProfileId = profileId?.trim();
  if (trimmedProfileId != null && trimmedProfileId.isNotEmpty) {
    payload['profileId'] = trimmedProfileId;
  }

  if (allowTextNotification != null) {
    payload['allowTextNotification'] = allowTextNotification;
  }

  if (address != null) {
    payload['address'] = <String, dynamic>{
      'addressLine1': address.line1.trim(),
      if (address.line2 != null && address.line2!.trim().isNotEmpty)
        'addressLine2': address.line2!.trim(),
      'city': address.city.trim(),
      'state': address.state.trim(),
      'postalCode': address.postalCode.trim(),
    };
  }

  return payload;
}

/// Splits a display full name into first / optional middle / last parts.
({String firstName, String? middleName, String lastName}) splitFullName(
  String fullName,
) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return (firstName: '', middleName: null, lastName: '');
  }
  if (parts.length == 1) {
    return (firstName: parts.first, middleName: null, lastName: '');
  }
  if (parts.length == 2) {
    return (firstName: parts.first, middleName: null, lastName: parts.last);
  }

  return (
    firstName: parts.first,
    middleName: parts.sublist(1, parts.length - 1).join(' '),
    lastName: parts.last,
  );
}
