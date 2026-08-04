import 'package:vcare_admin/features/profile/data/mappers/auth_me_update_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

class ProfileAddressModel {
  const ProfileAddressModel({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  factory ProfileAddressModel.fromJson(Map<String, dynamic> json) {
    return ProfileAddressModel(
      line1: json['line1'] as String? ?? '',
      line2: json['line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      if (line2 != null && line2!.isNotEmpty) 'line2': line2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }

  ProfileAddress toEntity() {
    return ProfileAddress(
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
    );
  }

  static ProfileAddressModel fromEntity(ProfileAddress address) {
    return ProfileAddressModel(
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
    );
  }
}

class LocalProfileModel {
  const LocalProfileModel({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    required this.email,
    required this.phone,
    required this.dob,
    this.gender = '',
    this.photoUrl,
    this.photoCacheKey,
    this.referralLink,
    this.agentCode,
    this.agencyGroupId,
    this.agencyName,
    this.address,
    this.bio,
    this.allowTextNotification = false,
    this.primaryCity,
    this.primaryState,
  });

  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String dob;
  final String gender;
  final String? photoUrl;
  final String? photoCacheKey;
  final String? referralLink;
  final String? agentCode;
  final String? agencyGroupId;
  final String? agencyName;
  final ProfileAddressModel? address;
  final String? bio;
  final bool allowTextNotification;
  final String? primaryCity;
  final String? primaryState;

  factory LocalProfileModel.fromJson(Map<String, dynamic> json) {
    final rawAddress = json['address'];
    final firstName = json['firstName'] as String? ?? '';
    final middleName = json['middleName'] as String? ?? '';
    final lastName = json['lastName'] as String? ?? '';
    final legacyFullName = json['fullName'] as String? ?? '';

    // Migrate older vcare.profile.v2 payloads that only stored fullName.
    final resolvedNames = (firstName.trim().isEmpty && lastName.trim().isEmpty)
        ? splitFullName(legacyFullName)
        : (firstName: firstName, middleName: middleName, lastName: lastName);

    return LocalProfileModel(
      firstName: resolvedNames.firstName,
      middleName: resolvedNames.middleName ?? '',
      lastName: resolvedNames.lastName,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      photoCacheKey: json['photoCacheKey'] as String?,
      referralLink: json['referralLink'] as String?,
      agentCode: json['agentCode'] as String?,
      agencyGroupId: json['agencyGroupId'] as String?,
      agencyName: json['agencyName'] as String?,
      address: rawAddress is Map
          ? ProfileAddressModel.fromJson(Map<String, dynamic>.from(rawAddress))
          : null,
      bio: json['bio'] as String?,
      allowTextNotification: json['allowTextNotification'] == true,
      primaryCity: json['primaryCity'] as String?,
      primaryState: json['primaryState'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final profile = toEntity();
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      // Keep fullName for older readers / debugging.
      'fullName': profile.joinedName,
      'email': email,
      'phone': phone,
      'dob': dob,
      if (gender.isNotEmpty) 'gender': gender,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoCacheKey != null) 'photoCacheKey': photoCacheKey,
      if (referralLink != null) 'referralLink': referralLink,
      if (agentCode != null) 'agentCode': agentCode,
      if (agencyGroupId != null) 'agencyGroupId': agencyGroupId,
      if (agencyName != null) 'agencyName': agencyName,
      if (address != null) 'address': address!.toJson(),
      if (bio != null) 'bio': bio,
      'allowTextNotification': allowTextNotification,
      if (primaryCity != null) 'primaryCity': primaryCity,
      if (primaryState != null) 'primaryState': primaryState,
    };
  }

  LocalProfile toEntity() {
    return LocalProfile(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      dob: dob,
      gender: gender,
      photoUrl: photoUrl,
      photoCacheKey: photoCacheKey,
      referralLink: referralLink,
      agentCode: agentCode,
      agencyGroupId: agencyGroupId,
      agencyName: agencyName,
      address: address?.toEntity(),
      bio: bio,
      allowTextNotification: allowTextNotification,
      primaryCity: primaryCity,
      primaryState: primaryState,
    );
  }

  static LocalProfileModel fromEntity(LocalProfile profile) {
    return LocalProfileModel(
      firstName: profile.firstName,
      middleName: profile.middleName,
      lastName: profile.lastName,
      email: profile.email,
      phone: profile.phone,
      dob: profile.dob,
      gender: profile.gender,
      photoUrl: profile.photoUrl,
      photoCacheKey: profile.photoCacheKey,
      referralLink: profile.referralLink,
      agentCode: profile.agentCode,
      agencyGroupId: profile.agencyGroupId,
      agencyName: profile.agencyName,
      address: profile.address == null
          ? null
          : ProfileAddressModel.fromEntity(profile.address!),
      bio: profile.bio,
      allowTextNotification: profile.allowTextNotification,
      primaryCity: profile.primaryCity,
      primaryState: profile.primaryState,
    );
  }
}
