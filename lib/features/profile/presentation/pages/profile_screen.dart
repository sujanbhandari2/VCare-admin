import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/account/data/mappers/account_mapper.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_actions_card.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_details_section.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_header_card.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_sign_out_footer.dart';
import 'package:vcare_admin/shared/session/user_session_cleanup.dart';
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
    await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
  }

  Future<void> _signOut() async {
    await clearUserSession(ref, navigateToLogin: true);
  }

  @override
  Widget build(BuildContext context) {
    final authMeState = ref.watch(authMeStateProvider);
    final user = authMeState.user;
    final fetching = authMeState.fetching && user == null;
    final error = authMeState.error;

    return Scaffold(
      body: VcareRefreshScrollView(
        onRefresh: _onRefresh,
        slivers: [
          const SliverVcarePageHeader(title: 'My Account', showBack: false),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (fetching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (user == null)
                  _AccountLoadError(
                    message: error ?? 'Could not load your account.',
                    onRetry: _onRefresh,
                  )
                else ...[
                  AccountHeaderCard(user: user),
                  const SizedBox(height: 16),
                  AccountDetailsSection(user: user),
                  const SizedBox(height: 16),
                  AccountActionsCard(
                    onEditProfile: () =>
                        context.pushNamed(AppRouter.profileEditName),
                    onChangePassword: () =>
                        context.pushNamed(AppRouter.profilePasswordName),
                  ),
                  if (isSsoAccount(user)) ...[
                    const SizedBox(height: 12),
                    const _SsoPasswordHint(),
                  ],
                  const SizedBox(height: 24),
                  ProfileSignOutFooter(onSignOut: _signOut),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountLoadError extends StatelessWidget {
  const _AccountLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final danger = VCareStatusColors.of(context, VCareStatusTone.danger);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.alertCircle, color: danger.foreground),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: danger.foreground),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text('Try again', style: TextStyle(color: vcare.primary)),
          ),
        ],
      ),
    );
  }
}

class _SsoPasswordHint extends StatelessWidget {
  const _SsoPasswordHint();

  @override
  Widget build(BuildContext context) {
    final info = VCareStatusColors.of(context, VCareStatusTone.info);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shield, size: 16, color: info.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your organization uses single sign-on. Password changes are managed by your identity provider.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: info.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
