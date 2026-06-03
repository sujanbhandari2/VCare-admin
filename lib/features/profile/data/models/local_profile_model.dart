import 'package:flutter_template/features/profile/domain/entities/local_profile.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_address.dart';

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
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dob,
    this.photoUrl,
    this.address,
  });

  final String fullName;
  final String email;
  final String phone;
  final String dob;
  final String? photoUrl;
  final ProfileAddressModel? address;

  factory LocalProfileModel.fromJson(Map<String, dynamic> json) {
    final rawAddress = json['address'];
    return LocalProfileModel(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      address: rawAddress is Map
          ? ProfileAddressModel.fromJson(Map<String, dynamic>.from(rawAddress))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'dob': dob,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (address != null) 'address': address!.toJson(),
    };
  }

  LocalProfile toEntity() {
    return LocalProfile(
      fullName: fullName,
      email: email,
      phone: phone,
      dob: dob,
      photoUrl: photoUrl,
      address: address?.toEntity(),
    );
  }

  static LocalProfileModel fromEntity(LocalProfile profile) {
    return LocalProfileModel(
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      dob: profile.dob,
      photoUrl: profile.photoUrl,
      address: profile.address == null
          ? null
          : ProfileAddressModel.fromEntity(profile.address!),
    );
  }
}
