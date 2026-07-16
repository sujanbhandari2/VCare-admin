import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

class CommonIcon extends StatelessWidget {
  const CommonIcon({super.key, this.icon, this.size = 24.0, this.color});

  /// [icon] might be IconData or icon assetsName or icon url
  /// e.g. Icons.add, or "assets/icons/my-icon.png", or "https://image.com/icon.png"
  ///
  final dynamic icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return icon is String || icon is IconData
        ? icon is String
              ? (icon as String).isUrl
                    ? icon.contains(".svg")
                          ? SvgPicture.network(
                              icon,
                              width: size,
                              height: size,
                              colorFilter: color != null
                                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                                  : null,
                            )
                          : VCareCachedImage(
                              imageUrl: icon,
                              width: size,
                              height: size,
                              color: color,
                              errorWidget: const SizedBox(),
                            )
                    : (icon as String).contains("assets")
                    ? (icon as String).endsWith(".svg")
                          ? SvgPicture.asset(
                              icon,
                              width: size,
                              height: size,
                              colorFilter: color != null
                                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                                  : null,
                            )
                          : Image.asset(
                              icon,
                              width: size,
                              height: size,
                              errorBuilder: (_, err, trace) => const SizedBox(),
                              color: color,
                            )
                    : (icon as String).endsWith(".svg")
                    ? SvgPicture.asset(
                        "assets/svg/$icon",
                        width: size,
                        height: size,
                        colorFilter: color != null
                            ? ColorFilter.mode(color!, BlendMode.srcIn)
                            : null,
                      )
                    : Image.asset(
                        "assets/images/$icon",
                        width: size,
                        height: size,
                        errorBuilder: (_, err, trace) => const SizedBox(),
                        color: color,
                      )
              : Icon(icon, size: size, color: color)
        : const SizedBox();
  }
}
