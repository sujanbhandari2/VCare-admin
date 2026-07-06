import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/common_image.dart';

/// Profile photo with initials fallback when [photoUrl] is null or fails to load.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 64,
    this.borderRadius = 16,
    this.circular = false,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final double borderRadius;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final radius = circular ? size / 2 : borderRadius;
    final trimmedPhotoUrl = photoUrl?.trim();
    final hasPhoto = trimmedPhotoUrl != null && trimmedPhotoUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: hasPhoto
            ? _ProfilePhoto(
                photoUrl: trimmedPhotoUrl,
                size: size,
                name: name,
              )
            : _InitialsAvatar(name: name, size: size),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.photoUrl,
    required this.size,
    required this.name,
  });

  final String photoUrl;
  final double size;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isUrl) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) =>
            _InitialsAvatar(name: name, size: size),
      );
    }

    if (photoUrl.isFilePath) {
      return Image.file(
        File(photoUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _InitialsAvatar(name: name, size: size),
      );
    }

    return CommonImage(
      assetsOrUrlOrPath: photoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final initials = profileInitials(name);

    return ColoredBox(
      color: vcare.muted,
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            color: vcare.mutedForeground,
          ),
        ),
      ),
    );
  }
}
