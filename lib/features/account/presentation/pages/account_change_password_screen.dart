import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';
import 'package:vcare_admin/core/styles/vcare_status_colors.dart';
import 'package:vcare_admin/features/account/data/mappers/account_mapper.dart';
import 'package:vcare_admin/features/account/presentation/providers/account_password_state_provider.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_password_requirements.dart';
import 'package:vcare_admin/features/account/utils/account_validators.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/shared/session/user_session_cleanup.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Change password screen — mirrors web `AccountPassword` + SSO guard.
class AccountChangePasswordScreen extends ConsumerStatefulWidget {
  const AccountChangePasswordScreen({super.key});

  @override
  ConsumerState<AccountChangePasswordScreen> createState() =>
      _AccountChangePasswordScreenState();
}

class _AccountChangePasswordScreenState
    extends ConsumerState<AccountChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountPasswordStateProvider.notifier).reset();
      final user = ref.read(authMeStateProvider).user;
      if (user == null) {
        ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: false);
      }
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final success =
        await ref.read(accountPasswordStateProvider.notifier).changePassword(
              currentPassword: _currentController.text,
              newPassword: _newController.text,
              confirmPassword: _confirmController.text,
            );

    if (!mounted) {
      return;
    }

    if (!success) {
      final message = ref.read(accountPasswordStateProvider).error ??
          'Could not update password';
      context.showVcareToast(
        title: 'Could not update password',
        description: message,
        variant: VcareToastVariant.destructive,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    context.showVcareToast(
      title: 'Password updated',
      description: 'Please sign in again with your new password.',
      variant: VcareToastVariant.success,
      duration: const Duration(seconds: 2),
    );

    await clearUserSession(ref);
    if (!mounted) {
      return;
    }
    context.goNamed(AppRouter.login.toPathName);
  }

  @override
  Widget build(BuildContext context) {
    final authMeState = ref.watch(authMeStateProvider);
    final passwordState = ref.watch(accountPasswordStateProvider);
    final user = authMeState.user;
    final saving = passwordState.saving;
    final sso = user != null && isSsoAccount(user);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverVcarePageHeader(title: 'Password', showBack: true),
          SliverPadding(
            padding: context.mobileShellScrollPadding.copyWith(top: 8),
            sliver: SliverToBoxAdapter(
              child: user == null && authMeState.fetching
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : sso
                      ? const _SsoBlockedCard()
                      : Form(
                          key: _formKey,
                          onChanged: () => setState(() {}),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SignOutWarning(),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _currentController,
                                label: 'Current password',
                                hint: 'Current password',
                                obscureText: true,
                                required: true,
                                enabled: !saving,
                                textInputAction: TextInputAction.next,
                                validator:
                                    AccountValidators.validateCurrentPassword,
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _newController,
                                label: 'New password',
                                hint: 'New password',
                                obscureText: true,
                                required: true,
                                enabled: !saving,
                                textInputAction: TextInputAction.next,
                                validator:
                                    AccountValidators.validateNewPassword,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              AccountPasswordRequirements(
                                password: _newController.text,
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _confirmController,
                                label: 'Confirm new password',
                                hint: 'Confirm new password',
                                obscureText: true,
                                required: true,
                                enabled: !saving,
                                textInputAction: TextInputAction.done,
                                validator: (value) =>
                                    AccountValidators.validateConfirmPassword(
                                  newPassword: _newController.text,
                                  confirmPassword: value,
                                ),
                                onSubmitted: (_) {
                                  if (!saving) {
                                    _submit();
                                  }
                                },
                              ),
                              const SizedBox(height: 28),
                              AppButton.elevated(
                                text: 'Update password',
                                icon: LucideIcons.keyRound,
                                loading: saving,
                                onPressed: saving ? null : _submit,
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SsoBlockedCard extends StatelessWidget {
  const _SsoBlockedCard();

  @override
  Widget build(BuildContext context) {
    final info = VCareStatusColors.of(context, VCareStatusTone.info);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: info.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.shield, size: 28, color: info.foreground),
          const SizedBox(height: 12),
          Text(
            'Password managed by SSO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: info.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your organization uses single sign-on. Change your password with your identity provider.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: info.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutWarning extends StatelessWidget {
  const _SignOutWarning();

  @override
  Widget build(BuildContext context) {
    final warning = VCareStatusColors.of(context, VCareStatusTone.warning);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning.background,
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: warning.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, size: 16, color: warning.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Changing your password signs you out on all devices. You’ll need to sign in again.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: warning.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
