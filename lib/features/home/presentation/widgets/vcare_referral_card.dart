import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/vcare_assets.dart';
import 'package:flutter_template/features/home/presentation/widgets/referral_qr_code.dart';
import 'package:flutter_template/features/home/utils/referral_actions.dart';
import 'package:flutter_template/features/home/utils/referral_utils.dart';
import 'package:flutter_template/features/profile/domain/entities/local_profile.dart';

/// Agency label on referral card — parity with vcareapp [VCareReferralCard].
const kReferralAgencyName = 'BlueShield National';

/// Full referral card + link copy block — parity with [VCareReferralCard].
class VcareReferralCard extends StatefulWidget {
  const VcareReferralCard({
    super.key,
    required this.profile,
    this.hideInternalLabel = false,
  });

  final LocalProfile profile;
  final bool hideInternalLabel;

  @override
  State<VcareReferralCard> createState() => _VcareReferralCardState();
}

class _VcareReferralCardState extends State<VcareReferralCard> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final actions = ReferralActions(widget.profile);
    final username = referralUsernameFromEmail(widget.profile.email);
    final qrUrl = referralQrImageUrl(actions.referralUrl, size: 320);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: vcare.gradientCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -64,
                  top: -64,
                  child: Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -48,
                  bottom: -80,
                  child: Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              VCareAssets.vIcon,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (!widget.hideInternalLabel)
                            Text(
                              'MY REFERRAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profile.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@$username',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.profile.phone,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Text(
                                'SCAN TO JOIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ReferralQrCode(
                                imageUrl: qrUrl,
                                size: 112,
                                padding: 6,
                                borderRadius: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.building2,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AGENCY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    kReferralAgencyName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: vcare.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vcare.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Referral link',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: vcare.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            actions.referralUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: VCareColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () async {
                          await actions.copyReferralLink();
                          if (!mounted) return;
                          setState(() => _copied = true);
                          Future<void>.delayed(
                            const Duration(milliseconds: 1500),
                            () {
                              if (mounted) setState(() => _copied = false);
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _copied
                                    ? LucideIcons.check
                                    : LucideIcons.copy,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _copied ? 'Copied' : 'Copy',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this link or scan the QR on your card to refer a friend.',
                  style: TextStyle(
                    fontSize: 11,
                    color: vcare.mutedForeground,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
