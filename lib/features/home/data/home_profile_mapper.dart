import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/home/data/home_models.dart';
import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/features/home/utils/referral_utils.dart';

/// Maps [LocalProfile] into home UI models (parity with vcareapp profile-store on home).
HomeMember homeMemberFromProfile(LocalProfile profile) {
  final dob = profile.dob.trim();
  return HomeMember(
    fullName: profile.fullName,
    memberId: '',
    plan: '',
    photoAsset: profile.photoUrl ?? '',
    email: profile.email,
    phone: AuthPhoneFormatter.formatInternationalDisplay(profile.phone),
    dobLabel: dob.isEmpty ? '' : formatProfileDob(dob),
    groupNumber: '',
    effectiveDate: '',
    referralUrl: resolveReferralUrl(
      email: profile.email,
      referralLink: profile.referralLink,
    ),
    referralCode: profile.agentCode?.trim().isNotEmpty == true
        ? profile.agentCode!.trim()
        : null,
  );
}

HomeProfile homeProfileFromLocal(
  LocalProfile profile, {
  AuthMe? authMe,
}) {
  return HomeProfile(
    fullName: profile.fullName,
    photoUrl: authMe?.profilePhotoUrl ?? profile.photoUrl,
    photoCacheKey: authMe?.profilePhotoCacheKey ?? profile.photoCacheKey,
  );
}
