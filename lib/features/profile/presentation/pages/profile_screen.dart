import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/data/vcare_mock_auth.dart';
import 'package:vcare_admin/features/profile/data/mappers/family_member_mapper.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/family_members_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_family_section.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_settings_nav.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_sign_out_footer.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_summary_card.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRefresh();
    });
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }

    await Future.wait([
      ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true),
      ref.read(familyMembersStateProvider.notifier).fetchFamilyMembers(),
    ]);
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
    final profile = ref.watch(localProfileStateProvider);
    final familyState = ref.watch(familyMembersStateProvider);
    final family =
        familyState.members.map((member) => member.toProfileFamilyMember()).toList();

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        slivers: [
          const SliverToBoxAdapter(
            child: VcarePageHeader(title: 'Profile', showBack: false),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
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
                  family: family,
                  fetching: familyState.fetching,
                  error: familyState.error,
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
