import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

/// Parity profile model matching vcareapp [Profile] in profile-store.
class LocalProfile {
  const LocalProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dob,
    this.photoUrl,
    this.referralLink,
    this.address,
  });

  final String fullName;
  final String email;
  final String phone;
  final String dob;
  final String? photoUrl;
  final String? referralLink;
  final ProfileAddress? address;

  LocalProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? dob,
    String? photoUrl,
    String? referralLink,
    ProfileAddress? address,
    bool clearAddress = false,
    bool clearPhoto = false,
    bool clearReferralLink = false,
  }) {
    return LocalProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      referralLink:
          clearReferralLink ? null : (referralLink ?? this.referralLink),
      address: clearAddress ? null : (address ?? this.address),
    );
  }
}
