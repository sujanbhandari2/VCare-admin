import 'package:vcare_admin/features/home/data/home_mock_data.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/features/home/utils/referral_utils.dart';

/// Maps [LocalProfile] into home UI models (parity with vcareapp profile-store on home).
HomeMember homeMemberFromProfile(LocalProfile profile) {
  final base = HomeMockData.member;
  return HomeMember(
    fullName: profile.fullName,
    memberId: base.memberId,
    plan: base.plan,
    photoAsset: profile.photoUrl ?? base.photoAsset,
    email: profile.email,
    phone: profile.phone,
    dobLabel: profile.dob.isEmpty
        ? base.dobLabel
        : formatProfileDob(profile.dob),
    groupNumber: base.groupNumber,
    effectiveDate: base.effectiveDate,
    referralUrl: resolveReferralUrl(
      email: profile.email,
      referralLink: profile.referralLink,
    ),
  );
}

HomeProfile homeProfileFromLocal(LocalProfile profile) {
  return HomeProfile(
    fullName: profile.fullName,
    photoUrl: profile.photoUrl,
  );
}
