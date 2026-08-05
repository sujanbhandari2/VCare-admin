import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/features/home/presentation/widgets/referral_share_sheet.dart';
import 'package:vcare_admin/features/home/presentation/widgets/vcare_referral_card.dart';
import 'package:vcare_admin/features/home/utils/referral_actions.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// My Referral detail — parity with vcareapp [/id-card].
class IdCardScreen extends ConsumerStatefulWidget {
  const IdCardScreen({super.key});

  static const double _horizontalPadding = 20;

  @override
  ConsumerState<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends ConsumerState<IdCardScreen> {
  final GlobalKey _cardCaptureKey = GlobalKey();
  bool _isSharing = false;
  bool _isDownloading = false;

  bool get _isBusy => _isSharing || _isDownloading;

  Future<void> _onShareCard(ReferralActions actions) async {
    if (_isBusy) return;

    setState(() => _isSharing = true);
    try {
      final shared = await actions.shareCardImage();
      if (!mounted) return;

      if (!shared) {
        context.showVcareToast(
          title: "Couldn't share referral card",
          variant: VcareToastVariant.destructive,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _onDownloadCard(ReferralActions actions) async {
    if (_isBusy) return;

    setState(() => _isDownloading = true);
    try {
      final saved = await actions.downloadCardToGallery();
      if (!mounted) return;

      if (saved) {
        context.showVcareToast(
          title: 'Referral card saved',
          description: 'Saved to your gallery',
          variant: VcareToastVariant.success,
        );
      } else {
        context.showVcareToast(
          title: "Couldn't save referral card",
          description: 'Check photo library permissions and try again',
          variant: VcareToastVariant.destructive,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(localProfileStateProvider);
    final actions = ReferralActions(
      profile,
      cardCaptureKey: _cardCaptureKey,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverVcarePageHeader(
            title: 'My Referral',
            showBack: true,
            showBell: false,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReferralHeaderActionButton(
                  tooltip: 'Share referral card',
                  icon: LucideIcons.share2,
                  isLoading: _isSharing,
                  onPressed: _isBusy ? null : () => _onShareCard(actions),
                ),
                _ReferralHeaderActionButton(
                  tooltip: 'Download referral card',
                  icon: LucideIcons.download,
                  isLoading: _isDownloading,
                  onPressed: _isBusy ? null : () => _onDownloadCard(actions),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              IdCardScreen._horizontalPadding,
              0,
              IdCardScreen._horizontalPadding,
              context.mobileShellBottomContentPadding,
            ),
            sliver: SliverToBoxAdapter(
              child: VcareReferralCard(
                profile: profile,
                hideInternalLabel: true,
                cardCaptureKey: _cardCaptureKey,
                onShareLink: () => showReferralShareSheet(
                  context,
                  profile: profile,
                  cardCaptureKey: _cardCaptureKey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralHeaderActionButton extends StatelessWidget {
  const _ReferralHeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
    );
  }
}
