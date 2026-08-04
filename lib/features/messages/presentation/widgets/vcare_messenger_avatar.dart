import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/image/stable_image_cache_key.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

/// Avatar styling aligned with [CareAvatar] and mock Messages list rows.
///
/// Uses initials as the loading placeholder so list/sheet rows never sit on a
/// long shimmer while remote profile photos download.
class VcareMessengerAvatar extends StatelessWidget {
  const VcareMessengerAvatar({
    super.key,
    required this.displayTitle,
    this.imageUrl,
    this.isGroup = false,
    this.size = 48,
    this.borderRadius = 16,
  });

  final String displayTitle;
  final String? imageUrl;
  final bool isGroup;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final radius = BorderRadius.circular(borderRadius);

    if (isGroup) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: vcare.accent.withValues(alpha: 0.1),
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.users,
          color: vcare.accent,
          size: size * 0.5,
        ),
      );
    }

    final initials = _InitialsFallback(
      displayTitle: displayTitle,
      size: size,
      borderRadius: borderRadius,
      vcare: vcare,
    );

    final trimmedUrl = imageUrl?.trim();
    // Skip non-http(s) values (storage keys / relative paths) so we never sit
    // on a loading placeholder waiting for an unresolvable URL.
    if (trimmedUrl != null && trimmedUrl.isNotEmpty && trimmedUrl.isUrl) {
      return ClipRRect(
        borderRadius: radius,
        child: VCareCachedImage(
          imageUrl: trimmedUrl,
          cacheKey: stableImageCacheKey(
            prefix: 'messenger-avatar',
            imageUrl: trimmedUrl,
          ),
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: initials,
          errorWidget: initials,
        ),
      );
    }

    return initials;
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({
    required this.displayTitle,
    required this.size,
    required this.borderRadius,
    required this.vcare,
  });

  final String displayTitle;
  final double size;
  final double borderRadius;
  final VCareThemeExtension vcare;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: vcare.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(displayTitle),
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: vcare.accent,
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
