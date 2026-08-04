import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';

/// Parity profile model matching vcareapp [Profile] in profile-store.
class LocalProfile {
  const LocalProfile({
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

  /// UI gender label (`Male` / `Female` / `Others`), empty when unset.
  final String gender;
  final String? photoUrl;
  final String? photoCacheKey;
  final String? referralLink;
  final String? agentCode;
  final String? agencyGroupId;
  final String? agencyName;
  final ProfileAddress? address;
  final String? bio;
  final bool allowTextNotification;
  final String? primaryCity;
  final String? primaryState;

  /// Raw joined name parts without the `Member` display fallback.
  String get joinedName {
    return [firstName, middleName, lastName]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  /// Display name built from first / middle / last parts.
  /// Falls back to `Member` when no name parts are set (parity with web cache).
  String get fullName {
    final joined = joinedName;
    return joined.isEmpty ? 'Member' : joined;
  }

  bool get hasAgencyGroup {
    final name = agencyName?.trim();
    if (name != null && name.isNotEmpty) {
      return true;
    }
    final id = agencyGroupId?.trim();
    return id != null && id.isNotEmpty;
  }

  LocalProfile copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? dob,
    String? gender,
    String? photoUrl,
    String? photoCacheKey,
    String? referralLink,
    String? agentCode,
    String? agencyGroupId,
    String? agencyName,
    ProfileAddress? address,
    String? bio,
    bool? allowTextNotification,
    String? primaryCity,
    String? primaryState,
    bool clearAddress = false,
    bool clearPhoto = false,
    bool clearPhotoCacheKey = false,
    bool clearReferralLink = false,
    bool clearAgentCode = false,
    bool clearAgencyGroup = false,
    bool clearBio = false,
    bool clearPrimaryLocation = false,
  }) {
    return LocalProfile(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      photoCacheKey: clearPhotoCacheKey
          ? null
          : (photoCacheKey ?? this.photoCacheKey),
      referralLink:
          clearReferralLink ? null : (referralLink ?? this.referralLink),
      agentCode: clearAgentCode ? null : (agentCode ?? this.agentCode),
      agencyGroupId:
          clearAgencyGroup ? null : (agencyGroupId ?? this.agencyGroupId),
      agencyName: clearAgencyGroup ? null : (agencyName ?? this.agencyName),
      address: clearAddress ? null : (address ?? this.address),
      bio: clearBio ? null : (bio ?? this.bio),
      allowTextNotification:
          allowTextNotification ?? this.allowTextNotification,
      primaryCity: clearPrimaryLocation
          ? null
          : (primaryCity ?? this.primaryCity),
      primaryState: clearPrimaryLocation
          ? null
          : (primaryState ?? this.primaryState),
    );
  }
}
