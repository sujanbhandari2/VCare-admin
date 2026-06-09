import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

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
                          : CachedNetworkImage(
                              imageUrl: icon,
                              width: size,
                              height: size,
                              errorWidget: (_, err, trace) => const SizedBox(),
                              color: color,
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
