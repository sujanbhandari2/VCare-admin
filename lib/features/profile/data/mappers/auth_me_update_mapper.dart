import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

bool _hasCompleteAddress(ProfileEditFormData form) {
  return form.line1.trim().isNotEmpty &&
      form.city.trim().isNotEmpty &&
      form.state.trim().isNotEmpty &&
      form.postalCode.trim().isNotEmpty;
}

String? _normalizeMiddleName(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Builds a sparse address patch matching web `buildAddressPatch`.
Map<String, dynamic>? buildAddressPatch(
  ProfileEditFormData form,
  ProfileEditFormData initial,
) {
  final hasAddress = _hasCompleteAddress(form);
  final hadAddress = _hasCompleteAddress(initial);

  if (!hasAddress && !hadAddress) {
    return null;
  }

  if (hadAddress && !hasAddress) {
    return <String, dynamic>{
      'addressLine1': '',
      'addressLine2': null,
      'city': '',
      'state': '',
      'postalCode': '',
    };
  }

  if (!hadAddress && hasAddress) {
    return <String, dynamic>{
      'addressLine1': form.line1.trim(),
      'addressLine2':
          form.line2.trim().isEmpty ? null : form.line2.trim(),
      'city': form.city.trim(),
      'state': form.state.trim(),
      'postalCode': form.postalCode.trim(),
    };
  }

  final address = <String, dynamic>{};
  final line1 = form.line1.trim();
  final line2 = form.line2.trim();
  final city = form.city.trim();
  final state = form.state.trim();
  final postalCode = form.postalCode.trim();

  if (line1 != initial.line1.trim()) address['addressLine1'] = line1;
  if (line2 != initial.line2.trim()) {
    address['addressLine2'] = line2.isEmpty ? null : line2;
  }
  if (city != initial.city.trim()) address['city'] = city;
  if (state != initial.state.trim()) address['state'] = state;
  if (postalCode != initial.postalCode.trim()) {
    address['postalCode'] = postalCode;
  }

  if (address.isEmpty) {
    return null;
  }
  return address;
}

/// Diff-only PATCH body matching web `buildProfileUpdateBody`.
///
/// [phoneForApi] / [initialPhoneForApi] should already be E.164 (or API) digits.
/// [profileId] is included when non-null (new upload) or when explicitly
/// clearing — pass `null` to omit; use a non-empty string for a new file id.
Map<String, dynamic> buildProfileUpdateBody({
  required ProfileEditFormData form,
  required ProfileEditFormData initial,
  required String phoneForApi,
  required String initialPhoneForApi,
  String? profileId,
  bool includeProfileId = false,
}) {
  final body = <String, dynamic>{};
  final firstName = form.firstName.trim();
  final lastName = form.lastName.trim();
  final middleName = _normalizeMiddleName(form.middleName);
  final initialMiddle = _normalizeMiddleName(initial.middleName);

  if (firstName != initial.firstName.trim()) body['firstName'] = firstName;
  if (middleName != initialMiddle) body['middleName'] = middleName;
  if (lastName != initial.lastName.trim()) body['lastName'] = lastName;
  if (form.email.trim() != initial.email.trim()) {
    body['email'] = form.email.trim();
  }

  if (phoneForApi != initialPhoneForApi) body['phone'] = phoneForApi;

  if (form.dob.trim() != initial.dob.trim()) {
    body['dateOfBirth'] = form.dob.trim();
  }

  if (form.gender.trim() != initial.gender.trim()) {
    final gender = mapProfileGenderUiToApi(form.gender);
    if (gender != null) body['gender'] = gender;
  }

  if (form.allowTextNotification != initial.allowTextNotification) {
    body['allowTextNotification'] = form.allowTextNotification;
  }

  final nextBio = form.bio.trim();
  final prevBio = initial.bio.trim();
  if (nextBio != prevBio) {
    body['bio'] = nextBio.isEmpty ? null : nextBio;
  }

  final address = buildAddressPatch(form, initial);
  if (address != null) body['address'] = address;

  final nextPrimaryCity = form.primaryCity.trim();
  final nextPrimaryState = form.primaryState.trim();
  final prevPrimaryCity = initial.primaryCity.trim();
  final prevPrimaryState = initial.primaryState.trim();
  if (nextPrimaryCity != prevPrimaryCity ||
      nextPrimaryState != prevPrimaryState) {
    body['primaryCity'] = nextPrimaryCity.isEmpty ? null : nextPrimaryCity;
    body['primaryState'] = nextPrimaryState.isEmpty ? null : nextPrimaryState;
  }

  if (includeProfileId) body['profileId'] = profileId;

  return body;
}

/// Builds the JSON body for `PATCH auth/me` (full payload — used by tests /
/// legacy callers). Prefer [buildProfileUpdateBody] for edits.
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
  bool clearAddress = false,
  String? primaryCity,
  String? primaryState,
  bool includePrimaryLocation = false,
  String? bio,
  bool includeBio = false,
}) {
  final payload = <String, dynamic>{
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'dateOfBirth': dateOfBirth.trim(),
  };

  final trimmedMiddle = middleName?.trim() ?? '';
  payload['middleName'] = trimmedMiddle.isEmpty ? null : trimmedMiddle;

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

  if (clearAddress) {
    payload['address'] = <String, dynamic>{
      'addressLine1': '',
      'addressLine2': null,
      'city': '',
      'state': '',
      'postalCode': '',
    };
  } else if (address != null) {
    payload['address'] = <String, dynamic>{
      'addressLine1': address.line1.trim(),
      'addressLine2': address.line2?.trim().isNotEmpty == true
          ? address.line2!.trim()
          : null,
      'city': address.city.trim(),
      'state': address.state.trim(),
      'postalCode': address.postalCode.trim(),
    };
  }

  if (includePrimaryLocation) {
    final trimmedCity = primaryCity?.trim() ?? '';
    final trimmedState = primaryState?.trim() ?? '';
    payload['primaryCity'] = trimmedCity.isEmpty ? null : trimmedCity;
    payload['primaryState'] = trimmedState.isEmpty ? null : trimmedState;
  }

  if (includeBio) {
    final trimmedBio = bio?.trim() ?? '';
    payload['bio'] = trimmedBio.isEmpty ? null : trimmedBio;
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
