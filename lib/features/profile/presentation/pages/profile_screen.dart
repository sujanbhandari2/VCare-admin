import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:flutter_template/app/router/app_router.dart';
import 'package:flutter_template/core/styles/vcare_colors.dart';
import 'package:flutter_template/core/styles/vcare_theme.dart';
import 'package:flutter_template/features/auth/data/vcare_mock_auth.dart';
import 'package:flutter_template/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:flutter_template/features/profile/presentation/providers/user_profile_state_provider.dart';
import 'package:flutter_template/features/profile/presentation/widgets/profile_family_section.dart';
import 'package:flutter_template/features/profile/presentation/widgets/profile_settings_nav.dart';
import 'package:flutter_template/features/profile/presentation/widgets/profile_sign_out_footer.dart';
import 'package:flutter_template/features/profile/presentation/widgets/profile_summary_card.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';
import 'package:flutter_template/shared/widgets/vcare_page_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      _fetchUserProfile();
    });
  }

  Future<void> _fetchUserProfile() async {
    if (mounted) {
      ref.read(userProfileStateProvider.notifier).fetchProfile();
    }
  }

  Future<void> _signOut() async {
    await VcareMockAuth.signOut(ref);
    if (!mounted) {
      return;
    }
    context.goNamed(AppRouter.login.toPathName);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileStateProvider);
    final profile = ref.watch(localProfileStateProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(title: 'Profile', showBack: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ProfileSummaryCard(
                  profile: profile,
                  onEdit: () => context.pushNamed(AppRouter.profileEditName),
                  onAddressTap: () =>
                      context.pushNamed(AppRouter.profileAddressName),
                ),
                const SizedBox(height: 20),
                ProfileFamilySection(
                  family: profileFamilySeed,
                  onAdd: () => context.pushNamed(AppRouter.familyMemberNewName),
                  onMemberTap: (id) => context.pushNamed(
                    AppRouter.familyMemberEditName,
                    pathParameters: {'id': id},
                  ),
                ),
                const SizedBox(height: 20),
                const ProfileSettingsNav(),
                const SizedBox(height: 20),
                _AppSettingsRow(
                  onTap: () => context.pushNamed(AppRouter.settings.toPathName),
                ),
                const SizedBox(height: 20),
                ProfileSignOutFooter(onSignOut: _signOut),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsRow extends StatelessWidget {
  const _AppSettingsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Material(
      color: vcare.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: vcare.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.settings, size: 20, color: VCareColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'App Settings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: vcare.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
