import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:vcare_admin/features/home/data/vcare_assets.dart';

/// Renders a tenant logo/icon from data URL, network URL, or bundled fallback.
class TenantBrandedImage extends StatelessWidget {
  const TenantBrandedImage({
    super.key,
    this.source,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.fallbackAsset = VCareAssets.logo,
    this.borderRadius,
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackAsset;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _buildImage() {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (value.startsWith('data:image')) {
      final bytes = _decodeDataUrl(value);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
      return _fallback();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (_, _, _) => _fallback(),
        placeholder: (_, _) => SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Treat as asset path if it looks local.
    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }

  static Uint8List? _decodeDataUrl(String dataUrl) {
    try {
      final comma = dataUrl.indexOf(',');
      if (comma < 0) return null;
      final meta = dataUrl.substring(0, comma);
      final data = dataUrl.substring(comma + 1);
      if (!meta.contains(';base64')) return null;
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }
}
