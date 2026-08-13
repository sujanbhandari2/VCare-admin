import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/image/stable_image_cache_key.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/utils/care_team_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

class CareAvatar extends StatelessWidget {
  const CareAvatar({
    super.key,
    required this.member,
    this.size = 56,
    this.borderRadius = 16,
  });

  final CareTeamMember member;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final fallback = _CareAvatarFallback(
      member: member,
      size: size,
      borderRadius: borderRadius,
    );
    final loadingPlaceholder = _CareAvatarShimmer(
      size: size,
      borderRadius: borderRadius,
    );

    if (member.photoAsset != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          member.photoAsset!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }

    final trimmedUrl = member.photoUrl?.trim();
    if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
      if (trimmedUrl.isUrl) {
        return ClipRRect(
          borderRadius: radius,
          child: VCareCachedImage(
            imageUrl: trimmedUrl,
            cacheKey: stableImageCacheKey(
              prefix: 'care-avatar',
              imageUrl: trimmedUrl,
            ),
            width: size,
            height: size,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            placeholder: loadingPlaceholder,
            errorWidget: fallback,
          ),
        );
      }

      if (trimmedUrl.isFilePath) {
        return ClipRRect(
          borderRadius: radius,
          child: Image.file(
            File(trimmedUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      }
    }

    return fallback;
  }
}

class _CareAvatarShimmer extends StatelessWidget {
  const _CareAvatarShimmer({required this.size, required this.borderRadius});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      loading: true,
      child: Shimmer.loadingContainer(
        context,
        width: size,
        height: size,
        radius: borderRadius,
      ),
    );
  }
}

class _CareAvatarFallback extends StatelessWidget {
  const _CareAvatarFallback({
    required this.member,
    required this.size,
    required this.borderRadius,
  });

  final CareTeamMember member;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final isInsurance = member.role == CareTeamRole.insurance;
    final bg = isInsurance
        ? context.vcare.primary.withValues(alpha: 0.1)
        : vcare.accent.withValues(alpha: 0.1);
    final fg = isInsurance ? context.vcare.primary : vcare.accent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: member.logoText != null
          ? Text(
              member.logoText!,
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            )
          : !member.isOrg
          ? Text(
              careTeamInitials(member.name),
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            )
          : Icon(LucideIcons.building2, size: size * 0.4, color: fg),
    );
  }
}
