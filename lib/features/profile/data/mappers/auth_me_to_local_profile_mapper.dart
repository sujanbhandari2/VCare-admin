import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

/// Maps the authenticated user from `GET auth/me` into the persisted
/// [LocalProfile] used by home header, profile screen, and ID card.
LocalProfile localProfileFromAuthMe(AuthMe authMe) {
  final user = authMe.user;
  final fullName = user.displayName;

  return LocalProfile(
    fullName: fullName.isEmpty ? 'Member' : fullName,
    email: user.email ?? '',
    phone: user.phoneNumber ?? '',
    dob: formatProfileDob(user.dateOfBirth),
    photoUrl: authMe.profilePhotoUrl,
    referralLink: authMe.referralLink,
  );
}

/// Backward-compatible helper when only [AuthMeUser] is available.
LocalProfile localProfileFromAuthMeUser(AuthMeUser user) {
  return localProfileFromAuthMe(
    AuthMe(user: user),
  );
}
