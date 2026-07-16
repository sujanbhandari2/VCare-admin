import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:vcare_admin/core/services/image/stable_image_cache_key.dart';
import 'package:vcare_admin/core/services/image/vcare_image_cache_manager.dart';

/// Displays a remote image with app-wide disk and memory caching.
///
/// Use this widget anywhere a network image is shown so repeated URLs load
/// from cache instead of re-downloading.
class VCareCachedImage extends StatelessWidget {
  const VCareCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.placeholder,
    this.errorWidget,
    this.showLoadingIndicator = false,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.useOldImageOnUrlChange = true,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingIndicator;
  final Duration fadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// Optional override for the cache entry key. Defaults to [imageUrl].
  final String? cacheKey;

  /// Keeps the previous image visible when [imageUrl] changes but [cacheKey]
  /// still resolves to the same cached file.
  final bool useOldImageOnUrlChange;

  @override
  Widget build(BuildContext context) {
    final resolvedMemCacheWidth =
        memCacheWidth ?? _resolveMemCacheDimension(context, width);
    final resolvedMemCacheHeight =
        memCacheHeight ?? _resolveMemCacheDimension(context, height);

    // Only pass one decode dimension so aspect ratio is preserved before
    // [BoxFit.cover] crops the image inside its layout box.
    final decodeWidth = resolvedMemCacheWidth;
    final decodeHeight =
        decodeWidth != null ? null : resolvedMemCacheHeight;

    // Prefer an explicit key, then a stable path-based key (strips signed URL
    // query params), then the raw URL so cache lookups stay consistent.
    final resolvedCacheKey = cacheKey ??
        stableImageCacheKey(
          prefix: 'network-image',
          imageUrl: imageUrl,
        ) ??
        imageUrl;

    final boundedImage = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: resolvedCacheKey,
      cacheManager: VCareImageCacheManager.instance,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      fadeInDuration: fadeInDuration,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      memCacheWidth: decodeWidth,
      memCacheHeight: decodeHeight,
      maxWidthDiskCache: decodeWidth,
      maxHeightDiskCache: decodeHeight,
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          fit: fit,
          alignment: alignment,
          color: color,
          colorBlendMode: colorBlendMode,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      },
      placeholder: showLoadingIndicator
          ? null
          : (_, _) => placeholder ?? const SizedBox.shrink(),
      progressIndicatorBuilder: showLoadingIndicator
          ? (context, url, progress) {
              return placeholder ??
                  Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
                    ),
                  );
            }
          : null,
      errorWidget: (_, _, _) =>
          errorWidget ?? const SizedBox.shrink(),
    );

    if (width == null && height == null) {
      return boundedImage;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(child: boundedImage),
    );
  }

  int? _resolveMemCacheDimension(BuildContext context, double? logicalSize) {
    if (logicalSize == null || !logicalSize.isFinite || logicalSize <= 0) {
      return null;
    }

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * devicePixelRatio).ceil();
  }
}
