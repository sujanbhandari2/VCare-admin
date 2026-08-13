import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/profile_photo_display_provider.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';

/// Avatar for the signed-in user with live auth/me photo resolution and refresh
/// when a signed preview URL expires.
class UserProfileAvatar extends ConsumerWidget {
  const UserProfileAvatar({
    super.key,
    required this.name,
    this.size = 64,
    this.borderRadius = 16,
    this.circular = false,
    this.initialsFontSize,
    this.initialsFontWeight,
    this.emptyIconSize,
    this.initialsColor,
  });

  final String name;
  final double size;
  final double borderRadius;
  final bool circular;
  final double? initialsFontSize;
  final FontWeight? initialsFontWeight;
  final double? emptyIconSize;
  final Color? initialsColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(profilePhotoDisplayProvider);

    return ProfileAvatar(
      name: name,
      photoUrl: photo.url,
      photoCacheKey: photo.cacheKey,
      size: size,
      borderRadius: borderRadius,
      circular: circular,
      initialsFontSize: initialsFontSize,
      initialsFontWeight: initialsFontWeight,
      emptyIconSize: emptyIconSize,
      initialsColor: initialsColor,
      onPhotoError: () {
        ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
      },
    );
  }
}
