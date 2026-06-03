import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/home/data/home_models.dart';
import 'package:flutter_template/features/home/data/vcare_assets.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_empty_state_card.dart';
import 'package:flutter_template/features/home/presentation/widgets/home_section_header.dart';
import 'package:flutter_template/features/home/presentation/widgets/referral_qr_code.dart';
import 'package:flutter_template/features/home/utils/referral_utils.dart';

class HomeMembershipSection extends StatelessWidget {
  const HomeMembershipSection({
    super.key,
    required this.member,
    required this.hasMembership,
    this.previewNoMembership = false,
    this.onPreviewToggle,
    this.onTap,
  });

  final HomeMember member;
  final bool hasMembership;
  final bool previewNoMembership;
  final VoidCallback? onPreviewToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'My Referral',
          showPreviewToggle: kDebugMode,
          previewEmpty: previewNoMembership,
          onPreviewToggle: onPreviewToggle,
        ),
        if (hasMembership)
          _ReferralCard(
            member: member,
            gradient: vcare.gradientCard,
            onTap: onTap,
          )
        else
          HomeEmptyStateCard(
            icon: LucideIcons.contact,
            title: 'No referral on file',
            description:
                'Add your insurance or plan card to unlock benefits, in-network providers and copay estimates.',
            ctaLabel: 'Add referral',
            onTap: onTap,
            borderRadius: 16,
          ),
      ],
    );
  }
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({
    required this.member,
    required this.gradient,
    this.onTap,
  });

  /// Matches web `min-h-[190px]`; fixed height keeps [Stack] bounded in slivers.
  static const double cardHeight = 190;

  final HomeMember member;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final referralUrl = referralUrlFromEmail(member.email);
    final qrUrl = referralQrImageUrl(referralUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: cardHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _ReferralWaveBackground(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MY REFERRAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  member.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member.phone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Text(
                                      'View full card details',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Image.asset(
                                VCareAssets.vIcon,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                              const Spacer(),
                              ReferralQrCode(imageUrl: qrUrl),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferralWaveBackground extends StatelessWidget {
  const _ReferralWaveBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ReferralWavePainter());
  }
}

class _ReferralWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bottomPaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    final bottomPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.55,
        size.width * 0.65,
        size.height * 1.0,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bottomPath, bottomPaint);

    final topPaint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final topPath = Path()
      ..moveTo(0, size.height * 0.2)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.45,
        size.width * 0.7,
        0,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(topPath, topPaint);
  }

  @override
  bool shouldRepaint(covariant _ReferralWavePainter oldDelegate) => false;
}
