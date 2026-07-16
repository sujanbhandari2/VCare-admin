import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Avatar styling aligned with [CareAvatar] and mock Messages list rows.
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

    final trimmedUrl = imageUrl?.trim();
    if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: trimmedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _InitialsFallback(
            displayTitle: displayTitle,
            size: size,
            borderRadius: borderRadius,
            vcare: vcare,
          ),
        ),
      );
    }

    return _InitialsFallback(
      displayTitle: displayTitle,
      size: size,
      borderRadius: borderRadius,
      vcare: vcare,
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
                    : const Color(0xFFEF4444),
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
