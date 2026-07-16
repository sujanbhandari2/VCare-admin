import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

class CommonImage extends StatelessWidget {
  const CommonImage({
    super.key,
    required this.assetsOrUrlOrPath,
    this.width,
    this.height,
    this.fit = .contain,
  });

  /// [assetsOrUrlOrPath] might be IconData or icon assetsName or icon url
  /// e.g. Icons.add, or "assets/icons/my-icon.png", or "https://image.com/icon.png"
  /// or directory/images/my_images.png
  ///
  final String assetsOrUrlOrPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return assetsOrUrlOrPath.isFilePath
        ? assetsOrUrlOrPath.contains(".svg")
              ? SvgPicture.file(
                  File(assetsOrUrlOrPath),
                  width: width,
                  height: height,
                  fit: fit,
                )
              : Image.file(
                  File(assetsOrUrlOrPath),
                  width: width,
                  height: height,
                  errorBuilder: (_, err, trace) => const SizedBox(),
                  fit: fit,
                )
        : assetsOrUrlOrPath.isUrl
        ? assetsOrUrlOrPath.contains(".svg")
              ? SvgPicture.network(
                  assetsOrUrlOrPath,
                  width: width,
                  height: height,
                  fit: fit,
                )
              : VCareCachedImage(
                  imageUrl: assetsOrUrlOrPath,
                  width: width,
                  height: height,
                  fit: fit,
                  errorWidget: const SizedBox(),
                )
        : assetsOrUrlOrPath.contains("assets")
        ? assetsOrUrlOrPath.endsWith(".svg")
              ? SvgPicture.asset(
                  assetsOrUrlOrPath,
                  width: width,
                  height: height,
                  fit: fit,
                )
              : Image.asset(
                  assetsOrUrlOrPath,
                  width: width,
                  height: height,
                  errorBuilder: (_, err, trace) => const SizedBox(),
                  fit: fit,
                )
        : assetsOrUrlOrPath.endsWith(".svg")
        ? SvgPicture.asset(
            "assets/svg/$assetsOrUrlOrPath",
            width: width,
            height: height,
            fit: fit,
          )
        : Image.asset(
            "assets/images/$assetsOrUrlOrPath",
            width: width,
            height: height,
            errorBuilder: (_, err, trace) => const SizedBox(),
            fit: fit,
          );
  }
}
