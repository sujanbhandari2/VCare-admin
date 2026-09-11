import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/services/image/stable_image_cache_key.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/common_image.dart';
import 'package:vcare_admin/shared/widgets/shimmer.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

/// Profile photo with initials fallback when [photoUrl] is null or fails to load.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.photoCacheKey,
    this.size = 64,
    this.borderRadius = 16,
    this.circular = false,
    this.initialsFontSize,
    this.initialsFontWeight,
    this.emptyIconSize,
    this.initialsColor,
    this.backgroundColor,
    this.onPhotoError,
  });

  final String name;
  final String? photoUrl;
  final String? photoCacheKey;
  final double size;
  final double borderRadius;
  final bool circular;
  final double? initialsFontSize;
  final FontWeight? initialsFontWeight;
  final double? emptyIconSize;
  final Color? initialsColor;
  final Color? backgroundColor;
  final VoidCallback? onPhotoError;

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
                photoCacheKey: photoCacheKey,
                size: size,
                borderRadius: radius,
                name: name,
                initialsFontSize: initialsFontSize,
                initialsFontWeight: initialsFontWeight,
                emptyIconSize: emptyIconSize,
                initialsColor: initialsColor,
                backgroundColor: backgroundColor,
                onPhotoError: onPhotoError,
              )
            : _InitialsAvatar(
                name: name,
                size: size,
                initialsFontSize: initialsFontSize,
                initialsFontWeight: initialsFontWeight,
                emptyIconSize: emptyIconSize,
                initialsColor: initialsColor,
                backgroundColor: backgroundColor,
              ),
      ),
    );
  }
}

class _ProfilePhoto extends StatefulWidget {
  const _ProfilePhoto({
    required this.photoUrl,
    this.photoCacheKey,
    required this.size,
    required this.borderRadius,
    required this.name,
    this.initialsFontSize,
    this.initialsFontWeight,
    this.emptyIconSize,
    this.initialsColor,
    this.backgroundColor,
    this.onPhotoError,
  });

  final String photoUrl;
  final String? photoCacheKey;
  final double size;
  final double borderRadius;
  final String name;
  final double? initialsFontSize;
  final FontWeight? initialsFontWeight;
  final double? emptyIconSize;
  final Color? initialsColor;
  final Color? backgroundColor;
  final VoidCallback? onPhotoError;

  @override
  State<_ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<_ProfilePhoto> {
  var _reloadToken = 0;
  var _reportedErrorForUrl = false;

  @override
  void didUpdateWidget(covariant _ProfilePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _reportedErrorForUrl = false;
      _reloadToken++;
    }
  }

  void _handlePhotoError() {
    if (_reportedErrorForUrl) return;
    _reportedErrorForUrl = true;
    widget.onPhotoError?.call();
  }

  @override
  Widget build(BuildContext context) {
    final initialsFallback = _InitialsAvatar(
      name: widget.name,
      size: widget.size,
      initialsFontSize: widget.initialsFontSize,
      initialsFontWeight: widget.initialsFontWeight,
      emptyIconSize: widget.emptyIconSize,
      initialsColor: widget.initialsColor,
      backgroundColor: widget.backgroundColor,
    );
    final loadingPlaceholder = _AvatarShimmerPlaceholder(
      size: widget.size,
      borderRadius: widget.borderRadius,
    );
    final resolvedCacheKey = widget.photoCacheKey ??
        stableImageCacheKey(
          prefix: 'profile-photo',
          imageUrl: widget.photoUrl,
        );
    final imageKey = ValueKey(
      '${resolvedCacheKey ?? widget.photoUrl}#$_reloadToken',
    );

    if (widget.photoUrl.isUrl) {
      return KeyedSubtree(
        key: imageKey,
        child: VCareCachedImage(
          imageUrl: widget.photoUrl,
          cacheKey: resolvedCacheKey,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
          placeholder: loadingPlaceholder,
          errorWidget: _ProfilePhotoError(
            fallback: initialsFallback,
            onError: _handlePhotoError,
          ),
        ),
      );
    }

    if (widget.photoUrl.isFilePath) {
      return Image.file(
        File(widget.photoUrl),
        key: imageKey,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initialsFallback,
      );
    }

    return CommonImage(
      assetsOrUrlOrPath: widget.photoUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
    );
  }
}

class _ProfilePhotoError extends StatefulWidget {
  const _ProfilePhotoError({
    required this.fallback,
    required this.onError,
  });

  final Widget fallback;
  final VoidCallback onError;

  @override
  State<_ProfilePhotoError> createState() => _ProfilePhotoErrorState();
}

class _ProfilePhotoErrorState extends State<_ProfilePhotoError> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onError();
    });
  }

  @override
  Widget build(BuildContext context) => widget.fallback;
}

class _AvatarShimmerPlaceholder extends StatelessWidget {
  const _AvatarShimmerPlaceholder({
    required this.size,
    required this.borderRadius,
  });

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

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.size,
    this.initialsFontSize,
    this.initialsFontWeight,
    this.emptyIconSize,
    this.initialsColor,
    this.backgroundColor,
  });

  final String name;
  final double size;
  final double? initialsFontSize;
  final FontWeight? initialsFontWeight;
  final double? emptyIconSize;
  final Color? initialsColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final initials = profileInitials(name);

    return ColoredBox(
      color: backgroundColor ?? vcare.muted,
      child: Center(
        child: initials.isEmpty
            ? Icon(
                LucideIcons.user,
                size: emptyIconSize ?? size * 0.33,
                color: vcare.mutedForeground,
              )
            : Text(
                initials,
                style: TextStyle(
                  fontSize: initialsFontSize ?? size * 0.35,
                  fontWeight: initialsFontWeight ?? FontWeight.w600,
                  color: initialsColor ?? vcare.mutedForeground,
                ),
              ),
      ),
    );
  }
}
