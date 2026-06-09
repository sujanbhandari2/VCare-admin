import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_theme.dart';

/// QR tile used on home referral card and detail/share surfaces.
class ReferralQrCode extends StatelessWidget {
  const ReferralQrCode({
    super.key,
    required this.imageUrl,
    this.size = 64,
    this.padding = 4,
    this.borderRadius = 12,
  });

  final String imageUrl;
  final double size;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final surface = Theme.of(context).colorScheme.surface;
    final innerRadius = borderRadius - 4;

    return Semantics(
      label: 'Referral QR code',
      child: Tooltip(
        message: 'Scan to refer',
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: vcare.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              innerRadius.clamp(0, borderRadius),
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, _) => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) => Icon(
                LucideIcons.qrCode,
                size: size * 0.45,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
