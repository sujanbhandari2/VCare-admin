import 'package:vcare_admin/features/profile/domain/entities/auth_me.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

/// Maps the authenticated user from `GET auth/me` into the persisted
/// [LocalProfile] used by home header, profile screen, and ID card.
LocalProfile localProfileFromAuthMe(AuthMe authMe) {
  final user = authMe.user;
  final agent = authMe.agentProfile;

  final fullName = _resolveFullName(user: user, agent: agent);
  final email = _firstNonEmpty([agent?.email, user.email]) ?? '';
  final phone = _firstNonEmpty([agent?.phoneNumber, user.phoneNumber]) ?? '';
  final dob = formatProfileDob(
    _firstNonEmpty([agent?.dateOfBirth, user.dateOfBirth]),
  );

  return LocalProfile(
    fullName: fullName.isEmpty ? 'Member' : fullName,
    email: email,
    phone: phone,
    dob: dob,
    photoUrl: authMe.profilePhotoUrl,
    photoCacheKey: authMe.profilePhotoCacheKey,
    referralLink: authMe.referralLink,
    agencyGroupId: _firstNonEmpty([
      user.agencyGroupId,
      agent?.agencyGroup?.id,
    ]),
    agencyName: _firstNonEmpty([
      user.agencyGroupName,
      agent?.agencyGroup?.name,
    ]),
    address: profileAddressFromAuthMeAddress(agent?.address),
  );
}

/// Backward-compatible helper when only [AuthMeUser] is available.
LocalProfile localProfileFromAuthMeUser(AuthMeUser user) {
  return localProfileFromAuthMe(
    AuthMe(user: user),
  );
}

/// Maps auth/me nested address fields into the profile edit address model.
ProfileAddress? profileAddressFromAuthMeAddress(AuthMeAddress? address) {
  if (address == null) {
    return null;
  }

  final line1 = address.addressLine1?.trim() ?? '';
  final line2 = address.addressLine2?.trim();
  final city = address.city?.trim() ?? '';
  final state = address.state?.trim() ?? '';
  final postalCode = address.postalCode?.trim() ?? '';
  final country = address.country?.trim();

  final hasAnyField = [
    line1,
    line2,
    city,
    state,
    postalCode,
    country,
  ].any((value) => value != null && value.isNotEmpty);
  if (!hasAnyField) {
    return null;
  }

  return ProfileAddress(
    line1: line1,
    line2: line2?.isEmpty == true ? null : line2,
    city: city,
    state: state,
    postalCode: postalCode,
    country: country?.isNotEmpty == true ? country! : 'United States',
  );
}

String _resolveFullName({
  required AuthMeUser user,
  AuthMeAgentProfile? agent,
}) {
  final agentName = agent?.displayName ?? '';
  if (agentName.isNotEmpty) {
    return agentName;
  }
  return user.displayName;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}
