import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';

part 'profile_photo_display_provider.g.dart';

/// Resolved profile photo URL and cache key for the signed-in user.
class ProfilePhotoDisplay {
  const ProfilePhotoDisplay({
    this.url,
    this.cacheKey,
  });

  final String? url;
  final String? cacheKey;
}

@Riverpod(keepAlive: true)
ProfilePhotoDisplay profilePhotoDisplay(Ref ref) {
  final authMe = ref.watch(authMeStateProvider).data;
  final profile = ref.watch(localProfileStateProvider);

  final photoUrl = _firstNonEmpty([
    authMe?.profilePhotoUrl,
    profile.photoUrl,
  ]);
  final photoCacheKey = authMe?.profilePhotoCacheKey ?? profile.photoCacheKey;

  return ProfilePhotoDisplay(
    url: photoUrl,
    cacheKey: photoCacheKey,
  );
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
