import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/home/presentation/widgets/referral_share_sheet.dart';
import 'package:vcare_admin/features/home/presentation/widgets/vcare_referral_card.dart';
import 'package:vcare_admin/features/home/utils/referral_actions.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

/// My Referral detail — parity with vcareapp [/id-card].
class IdCardScreen extends ConsumerWidget {
  const IdCardScreen({super.key});

  static const double _horizontalPadding = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(localProfileStateProvider);
    final actions = ReferralActions(profile);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: VcarePageHeader(
              title: 'My Referral',
              showBack: true,
              showBell: false,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () =>
                        showReferralShareSheet(context, profile: profile),
                    icon: const Icon(LucideIcons.share2, size: 20),
                    tooltip: 'Share referral',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                  IconButton(
                    onPressed: actions.saveQrImage,
                    icon: const Icon(LucideIcons.download, size: 20),
                    tooltip: 'Download referral QR',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              0,
              _horizontalPadding,
              32,
            ),
            sliver: SliverToBoxAdapter(
              child: VcareReferralCard(
                profile: profile,
                hideInternalLabel: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
