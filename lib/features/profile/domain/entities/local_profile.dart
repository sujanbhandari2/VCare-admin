import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

/// Parity profile model matching vcareapp [Profile] in profile-store.
class LocalProfile {
  const LocalProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dob,
    this.photoUrl,
    this.photoCacheKey,
    this.referralLink,
    this.agencyGroupId,
    this.agencyName,
    this.address,
  });

  final String fullName;
  final String email;
  final String phone;
  final String dob;
  final String? photoUrl;
  final String? photoCacheKey;
  final String? referralLink;
  final String? agencyGroupId;
  final String? agencyName;
  final ProfileAddress? address;

  bool get hasAgencyGroup {
    final name = agencyName?.trim();
    if (name != null && name.isNotEmpty) {
      return true;
    }
    final id = agencyGroupId?.trim();
    return id != null && id.isNotEmpty;
  }

  LocalProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? dob,
    String? photoUrl,
    String? photoCacheKey,
    String? referralLink,
    String? agencyGroupId,
    String? agencyName,
    ProfileAddress? address,
    bool clearAddress = false,
    bool clearPhoto = false,
    bool clearPhotoCacheKey = false,
    bool clearReferralLink = false,
    bool clearAgencyGroup = false,
  }) {
    return LocalProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      photoCacheKey: clearPhotoCacheKey
          ? null
          : (photoCacheKey ?? this.photoCacheKey),
      referralLink:
          clearReferralLink ? null : (referralLink ?? this.referralLink),
      agencyGroupId:
          clearAgencyGroup ? null : (agencyGroupId ?? this.agencyGroupId),
      agencyName: clearAgencyGroup ? null : (agencyName ?? this.agencyName),
      address: clearAddress ? null : (address ?? this.address),
    );
  }
}
