import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/qr_code_utils.dart';
import 'package:vcare_admin/shared/widgets/vcare_qr_code.dart';

/// QR tile used on home referral card and detail/share surfaces.
class ReferralQrCode extends StatelessWidget {
  const ReferralQrCode({
    super.key,
    required this.data,
    this.size = 64,
    this.padding = 4,
    this.borderRadius = 12,
  });

  final String data;
  final double size;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final surface = Theme.of(context).colorScheme.surface;
    final innerRadius = borderRadius - 4;
    final qrSize = size - (padding * 2);

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
            child: VcareQrCode(
              data: data,
              size: qrSize,
              decoration: QrCodeUtils.decoration(
                foreground: Colors.black,
                background: surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
