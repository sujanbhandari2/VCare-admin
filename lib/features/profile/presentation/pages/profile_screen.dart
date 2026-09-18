import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/features/account/data/mappers/account_mapper.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_actions_card.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_details_section.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_header_card.dart';
import 'package:vcare_admin/features/auth/presentation/providers/admin_auth_session_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/widgets/profile_sign_out_footer.dart';
import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_login_status.dart';
import 'package:vcare_admin/features/biometric_login/presentation/providers/biometric_login_state_provider.dart';
import 'package:vcare_admin/features/biometric_login/presentation/widgets/biometric_login_prompt_sheet.dart';
import 'package:vcare_admin/features/biometric_login/presentation/widgets/biometric_login_status_tile.dart';
import 'package:vcare_admin/shared/session/user_session_cleanup.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/shared/widgets/vcare_error_state_panel.dart';
import 'package:vcare_admin/shared/widgets/vcare_refresh_scroll_view.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountId = ref.read(adminAuthSessionProvider).user?.id;
      ref
          .read(biometricLoginStateProvider.notifier)
          .refreshStatus(accountId: accountId);
      _onRefresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 16;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      return;
    }
    await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
    final accountId = ref.read(adminAuthSessionProvider).user?.id;
    await ref
        .read(biometricLoginStateProvider.notifier)
        .refreshStatus(accountId: accountId);
  }

  Future<void> _signOut() async {
    await clearUserSession(ref, navigateToLogin: true);
  }

  Future<void> _toggleBiometric() async {
    final biometricState = ref.read(biometricLoginStateProvider);
    final session = ref.read(adminAuthSessionProvider);
    final accountId = session.user?.id.trim() ?? '';
    final status = biometricState.status ?? BiometricLoginStatus.disabled;
    final biometricLabel = status.displayType;

    if (status.isEnrolled) {
      final revoke = await showBiometricPromptSheet(
        context,
        title: biometricLabel == 'Face ID'
            ? 'Revoke Face ID?'
            : 'Revoke fingerprint?',
        description:
            'This removes Biometric sign-in from this device for now. You can enable it again later.',
        primaryLabel: 'Revoke Biometric',
        secondaryLabel: 'Keep it',
        biometricLabel: biometricLabel,
        onPrimaryPressed: () async {
          await ref
              .read(biometricLoginStateProvider.notifier)
              .revoke(
                accessToken: session.accessToken ?? '',
                onError: (message) {
                  if (message == null || !mounted) {
                    return;
                  }
                  context.showVcareToast(
                    title: 'Could not revoke biometric',
                    description: message,
                    variant: VcareToastVariant.destructive,
                  );
                },
                onCompleted: () {
                  if (!mounted) {
                    return;
                  }
                  context.showVcareToast(
                    title: 'Biometric disabled',
                    variant: VcareToastVariant.success,
                  );
                },
              );
        },
      );

      if (revoke != true) {
        return;
      }
      return;
    }

    final shouldEnable = await showBiometricPromptSheet(
      context,
      title: biometricLabel == 'Face ID'
          ? 'Enable Face ID?'
          : 'Enable fingerprint?',
      description: 'Use Biometric to log in faster from this device.',
      primaryLabel: 'Enable Biometric',
      secondaryLabel: 'Maybe later',
      biometricLabel: biometricLabel,
      onPrimaryPressed: () async {
        await ref
            .read(biometricLoginStateProvider.notifier)
            .enroll(
              accessToken: session.accessToken ?? '',
              accountId: accountId,
              accountEmail: session.user?.email,
              onError: (message) {
                if (message == null || !mounted) {
                  return;
                }
                context.showVcareToast(
                  title: 'Biometric enrollment failed',
                  description: message,
                  variant: VcareToastVariant.destructive,
                );
              },
            );
      },
    );

    if (shouldEnable != true) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authMeState = ref.watch(authMeStateProvider);
    final biometricState = ref.watch(biometricLoginStateProvider);
    final user = authMeState.user;
    final fetching = authMeState.fetching && user == null;
    final error = authMeState.error;
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: VcareRefreshScrollView(
        controller: _scrollController,
        onRefresh: _onRefresh,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: false,
              showBottomBorder: _scrolled,
              title: vcareTabPageTitle(title: 'My Account'),
            ),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding,
            sliver: fetching
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : user == null
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: VcareErrorStatePanel(
                      title: 'Unable to load account',
                      message: error ?? 'Could not load your account.',
                      actionLabel: context.appLocalization.retry,
                      onAction: _onRefresh,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate([
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
                      const SizedBox(height: 16),
                      BiometricLoginStatusTile(
                        status:
                            biometricState.status ??
                            BiometricLoginStatus.disabled,
                        loading: biometricState.loading,
                        onTap: _toggleBiometric,
                      ),
                      if (isSsoAccount(user)) ...[
                        const SizedBox(height: 12),
                        const _SsoPasswordHint(),
                      ],
                      const SizedBox(height: 24),
                      ProfileSignOutFooter(onSignOut: _signOut),
                    ]),
                  ),
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
