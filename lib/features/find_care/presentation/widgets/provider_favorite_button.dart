import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';

/// Heart toggle for save / unsave. Shows a filled heart when saved, and a
/// circular progress indicator while the request is in flight.
class ProviderFavoriteButton extends StatelessWidget {
  const ProviderFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.isToggling,
    required this.onPressed,
    this.iconSize = 18,
    this.minimumSize = const Size(36, 36),
    this.tooltip,
  });

  final bool isFavorite;
  final bool isToggling;
  final VoidCallback? onPressed;
  final double iconSize;
  final Size minimumSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final activeColor = VCareColors.destructive;
    final idleColor = vcare.mutedForeground;

    return IconButton(
      onPressed: isToggling ? null : onPressed,
      tooltip:
          tooltip ??
          (isFavorite ? 'Remove from favorites' : 'Save to favorites'),
      style: IconButton.styleFrom(
        backgroundColor: vcare.card.withValues(alpha: 0.9),
        side: BorderSide(color: vcare.border),
        minimumSize: minimumSize,
      ),
      icon: isToggling
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isFavorite ? activeColor : idleColor,
              ),
            )
          : Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: iconSize,
              color: isFavorite ? activeColor : idleColor,
            ),
    );
  }
}
