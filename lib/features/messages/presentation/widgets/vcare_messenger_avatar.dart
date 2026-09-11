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
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  final String displayTitle;
  final String? imageUrl;
  final bool isGroup;
  final double size;
  final double borderRadius;
  final bool showOnlineIndicator;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final radius = BorderRadius.circular(borderRadius);

    if (isGroup) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: vcare.primary.withValues(alpha: 0.12),
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.users,
          color: vcare.primary,
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
      return _withOnlineIndicator(
        context,
        ClipRRect(
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
        ),
      );
    }

    return _withOnlineIndicator(context, initials);
  }

  Widget _withOnlineIndicator(BuildContext context, Widget avatar) {
    if (!showOnlineIndicator || isGroup) {
      return avatar;
    }

    final vcare = context.vcare;
    final dotSize = size * 0.29;
    final dotColor = isOnline
        ? const Color(0xFF10B981)
        : vcare.mutedForeground.withValues(alpha: 0.6);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: vcare.card, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }
}

class VcareMessengerPresenceAvatar extends StatelessWidget {
  const VcareMessengerPresenceAvatar({
    super.key,
    required this.displayTitle,
    this.imageUrl,
    this.isGroup = false,
    this.isOnline = false,
    this.showOnlinePresence = true,
    this.size = 48,
    this.borderRadius = 16,
  });

  final String displayTitle;
  final String? imageUrl;
  final bool isGroup;
  final bool isOnline;
  final bool showOnlinePresence;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        VcareMessengerAvatar(
          displayTitle: displayTitle,
          imageUrl: imageUrl,
          isGroup: isGroup,
          size: size,
          borderRadius: borderRadius,
        ),
        if (showOnlinePresence && !isGroup)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFF22C55E)
                    : vcare.mutedForeground.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: vcare.card, width: 2.5),
              ),
            ),
          ),
      ],
    );
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
        // Primary tint keeps initials readable on admin themes where accent is
        // very light (ProfileAvatar uses muted; messenger matches list badges).
        color: vcare.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(displayTitle),
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: vcare.primary,
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
