import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/account/presentation/providers/account_edit_state_provider.dart';
import 'package:vcare_admin/features/account/presentation/widgets/account_photo_editor.dart';
import 'package:vcare_admin/features/account/utils/account_formatters.dart';
import 'package:vcare_admin/features/account/utils/account_validators.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Self-service profile edit — photo, first name, last name, email.
class AccountEditScreen extends ConsumerStatefulWidget {
  const AccountEditScreen({super.key});

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialEmail = '';
  String? _initialPhotoUrl;
  String? _initialPhotoCacheKey;
  String? _photoUrl;
  String? _photoCacheKey;
  bool _photoRemoved = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateFromAuthMe();
      ref.read(accountEditStateProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _hydrateFromAuthMe() {
    final authMe = ref.read(authMeStateProvider).data;
    final user = authMe?.user;
    if (user == null) {
      ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: false);
      return;
    }

    _initialFirstName = user.firstName?.trim() ?? '';
    _initialLastName = user.lastName?.trim() ?? '';
    _initialEmail = user.email?.trim() ?? '';
    _initialPhotoUrl = authMe?.profilePhotoUrl ?? user.profilePhotoUrl;
    _initialPhotoCacheKey = authMe?.profilePhotoCacheKey;
    _firstNameController.text = _initialFirstName;
    _lastNameController.text = _initialLastName;
    _emailController.text = _initialEmail;
    _photoUrl = _initialPhotoUrl;
    _photoCacheKey = _initialPhotoCacheKey;
    _photoRemoved = false;
    setState(() => _hydrated = true);
  }

  bool get _photoChanged =>
      isLocalAccountPhotoPath(_photoUrl) || _photoRemoved;

  bool get _isDirty {
    return _firstNameController.text.trim() != _initialFirstName ||
        _lastNameController.text.trim() != _initialLastName ||
        _emailController.text.trim().toLowerCase() !=
            _initialEmail.toLowerCase() ||
        _photoChanged;
  }

  bool get _canRemovePhoto {
    final hasInitial =
        _initialPhotoUrl != null && _initialPhotoUrl!.trim().isNotEmpty;
    final hasCurrent = _photoUrl != null && _photoUrl!.trim().isNotEmpty;
    return (hasInitial || hasCurrent) && !_photoRemoved;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final updated =
        await ref.read(accountEditStateProvider.notifier).saveProfile(
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              email: _emailController.text,
              photoUrl: _photoUrl,
              photoChanged: isLocalAccountPhotoPath(_photoUrl),
              photoRemoved: _photoRemoved,
            );

    if (!mounted) {
      return;
    }

    if (updated == null) {
      final message =
          ref.read(accountEditStateProvider).error ?? 'Could not save profile';
      context.showVcareToast(
        title: 'Could not save profile',
        description: message,
        variant: VcareToastVariant.destructive,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    context.showVcareToast(
      title: 'Profile updated',
      description: 'Your account details have been saved.',
      variant: VcareToastVariant.success,
      duration: const Duration(seconds: 2),
    );
    context.pop();
  }

  void _discard() {
    _firstNameController.text = _initialFirstName;
    _lastNameController.text = _initialLastName;
    _emailController.text = _initialEmail;
    setState(() {
      _photoUrl = _initialPhotoUrl;
      _photoCacheKey = _initialPhotoCacheKey;
      _photoRemoved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authMeState = ref.watch(authMeStateProvider);
    final editState = ref.watch(accountEditStateProvider);
    final saving = editState.saving;
    final user = authMeState.user;
    final displayName = AccountFormatters.displayName(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
    );

    ref.listen(authMeStateProvider, (previous, next) {
      if (!_hydrated && next.user != null) {
        _hydrateFromAuthMe();
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverVcarePageHeader(title: 'Edit profile', showBack: true),
          SliverPadding(
            padding: context.mobileShellScrollPadding.copyWith(top: 8),
            sliver: SliverToBoxAdapter(
              child: user == null && authMeState.fetching
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : user == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            authMeState.error ?? 'Could not load profile.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.vcare.mutedForeground,
                            ),
                          ),
                        )
                      : Form(
                          key: _formKey,
                          onChanged: () => setState(() {}),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Update your photo, name, and email shown across your workspace.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.vcare.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: AccountPhotoEditor(
                                  name: displayName,
                                  photoUrl: _photoRemoved ? null : _photoUrl,
                                  photoCacheKey:
                                      _photoRemoved ? null : _photoCacheKey,
                                  enabled: !saving,
                                  canRemove: _canRemovePhoto,
                                  onPhotoChanged: (path) {
                                    setState(() {
                                      _photoUrl = path;
                                      _photoCacheKey = null;
                                      _photoRemoved = false;
                                    });
                                  },
                                  onPhotoRemoved: () {
                                    setState(() {
                                      _photoUrl = null;
                                      _photoCacheKey = null;
                                      _photoRemoved = true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              AuthTextField(
                                controller: _firstNameController,
                                label: 'First name',
                                hint: 'First name',
                                required: true,
                                enabled: !saving,
                                textInputAction: TextInputAction.next,
                                maxLength: 50,
                                validator: AccountValidators.validateFirstName,
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _lastNameController,
                                label: 'Last name',
                                hint: 'Last name',
                                required: true,
                                enabled: !saving,
                                textInputAction: TextInputAction.next,
                                maxLength: 50,
                                validator: AccountValidators.validateLastName,
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email address',
                                hint: 'you@company.com',
                                required: true,
                                enabled: !saving,
                                inputType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                validator: AccountValidators.validateEmail,
                                onSubmitted: (_) {
                                  if (_isDirty && !saving) {
                                    _save();
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Used for sign-in and account notifications.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.vcare.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton.outlined(
                                      text: 'Discard',
                                      onPressed: (!_isDirty || saving)
                                          ? null
                                          : _discard,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton.elevated(
                                      text: 'Save changes',
                                      icon: LucideIcons.save,
                                      loading: saving,
                                      onPressed: (!_isDirty || saving)
                                          ? null
                                          : _save,
                                    ),
                                  ),
                                ],
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
