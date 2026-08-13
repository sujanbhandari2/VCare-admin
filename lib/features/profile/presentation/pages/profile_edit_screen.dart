import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/auth_national_phone_input_formatter.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_validator.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_phone_country_selector.dart';
import 'package:vcare_admin/features/places/domain/entities/parsed_address_parts.dart';
import 'package:vcare_admin/features/places/presentation/widgets/address_line1_autocomplete.dart';
import 'package:vcare_admin/features/places/presentation/widgets/primary_location_field.dart';
import 'package:vcare_admin/features/profile/data/mappers/auth_me_update_mapper.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/features/todo/presentation/providers/todo_list_state_provider.dart';
import 'package:vcare_admin/shared/layout/vcare_mobile_shell_insets.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';
import 'package:vcare_admin/core/styles/vcare_radius.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({
    super.key,
    this.addressOnly = false,
    this.initialTab = 'profile',
  });

  /// Kept for route parity with vcareapp `/profile/address` — same full form.
  final bool addressOnly;

  /// `profile` or `story` — parity with web `?tab=story`.
  final String initialTab;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _primaryCityController;
  late final TextEditingController _primaryStateController;
  late final TextEditingController _bioController;

  String _dob = '';
  String _gender = '';
  String? _photoUrl;
  String? _photoCacheKey;
  String? _initialPhotoUrl;
  bool _allowTextNotification = false;
  bool _addressCleared = false;
  ProfileEditFormData? _initialForm;
  String _initialPhoneForApi = '';
  static const _phoneCountry = AuthPhoneCountry.usa;
  static const _defaultCountry = 'United States';
  Map<String, String> _errors = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final startStory = widget.initialTab == 'story';
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: startStory ? 1 : 0,
    );
    _firstNameController = TextEditingController();
    _middleNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _line1Controller = TextEditingController();
    _line2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _primaryCityController = TextEditingController();
    _primaryStateController = TextEditingController();
    _bioController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileData());
  }

  Future<void> _loadProfileData() async {
    await ref.read(authMeStateProvider.notifier).fetchMe(forceRefresh: true);
    if (!mounted) {
      return;
    }

    _applyProfile(ref.read(localProfileStateProvider));
    setState(() => _loading = false);
  }

  void _applyProfile(LocalProfile profile) {
    final address = profile.address;
    final displayDigits = AuthPhoneFormatter.toDisplayDigits(
      profile.phone,
      fallback: _phoneCountry,
    );
    final phoneDisplay = AuthPhoneFormatter.formatNationalDisplay(
      displayDigits,
      _phoneCountry,
    );
    setState(() {
      _firstNameController.text = profile.firstName;
      _middleNameController.text = profile.middleName;
      _lastNameController.text = profile.lastName;
      _emailController.text = profile.email;
      _phoneController.text = phoneDisplay;
      _dob = profileDobToIso(profile.dob);
      _gender = profile.gender;
      _photoUrl = profile.photoUrl;
      _photoCacheKey = profile.photoCacheKey;
      _initialPhotoUrl = profile.photoUrl;
      _allowTextNotification = profile.allowTextNotification;
      _line1Controller.text = address?.line1 ?? '';
      _line2Controller.text = address?.line2 ?? '';
      _cityController.text = address?.city ?? '';
      _stateController.text = address?.state ?? '';
      _postalCodeController.text = address?.postalCode ?? '';
      _primaryCityController.text = profile.primaryCity ?? '';
      _primaryStateController.text = profile.primaryState ?? '';
      _bioController.text = profile.bio ?? '';
      _addressCleared = false;
      _initialPhoneForApi = AuthPhoneFormatter.toApiDigits(
        _phoneCountry.dialCode,
        phoneDisplay,
      );
      _initialForm = _currentForm();
    });
  }

  ProfileEditFormData _currentForm() {
    return ProfileEditFormData(
      firstName: _firstNameController.text,
      middleName: _middleNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      dob: _dob,
      gender: _gender,
      allowTextNotification: _allowTextNotification,
      line1: _line1Controller.text,
      line2: _line2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      postalCode: _postalCodeController.text,
      country: _defaultCountry,
      primaryCity: _primaryCityController.text,
      primaryState: _primaryStateController.text,
      bio: _bioController.text,
    );
  }

  String get _avatarDisplayName {
    final parts = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty);
    return parts.join(' ');
  }

  bool get _showProfileShineNudge {
    final hasPhoto = _photoUrl?.trim().isNotEmpty == true;
    final hasBio = _bioController.text.trim().isNotEmpty;
    return !hasPhoto || !hasBio;
  }

  Future<void> _submit() async {
    final form = _currentForm();
    final errors = ProfileEditValidation.validate(
      form,
      validatePhone: false,
    );
    final phoneError = AuthPhoneValidator.validate(
      _phoneController.text,
      country: _phoneCountry,
      context: context,
    );
    if (phoneError != null) {
      errors['phone'] = phoneError;
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      final first = errors.values.first;
      context.showVcareToast(
        title: 'Could not save profile',
        description: first,
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    final initial = _initialForm;
    if (initial == null) {
      return;
    }

    setState(() {
      _errors = {};
      _submitting = true;
    });

    final phoneForApi = AuthPhoneFormatter.toApiDigits(
      _phoneCountry.dialCode,
      _phoneController.text,
    );

    final photoChanged = _isLocalPhotoPath(_photoUrl) &&
        _photoUrl?.trim() != _initialPhotoUrl?.trim();

    final body = buildProfileUpdateBody(
      form: form,
      initial: initial,
      phoneForApi: phoneForApi,
      initialPhoneForApi: _initialPhoneForApi,
      includeProfileId: false,
    );

    final outcome = await ref.read(authMeStateProvider.notifier).updateMe(
          body: body,
          photoUrl: photoChanged ? _photoUrl : null,
        );

    if (!mounted) {
      return;
    }

    if (outcome == UpdateMeOutcome.failure) {
      final error = ref.read(authMeStateProvider).error;
      setState(() => _submitting = false);
      context.showVcareToast(
        title: error ?? 'Failed to update profile.',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    if (outcome == UpdateMeOutcome.noChanges) {
      setState(() => _submitting = false);
      context.showVcareToast(
        title: 'No changes to save',
        variant: VcareToastVariant.info,
      );
      context.pop();
      return;
    }

    await ref.read(todoListStateProvider.notifier).refresh();
    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);
    context.showVcareToast(
      title: 'Profile updated',
      variant: VcareToastVariant.success,
    );
    context.pop();
  }

  bool _isLocalPhotoPath(String? photoUrl) {
    final path = photoUrl?.trim();
    if (path == null || path.isEmpty) return false;
    final lower = path.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return false;
    }
    if (lower.startsWith('assets/')) {
      return false;
    }
    return true;
  }

  Future<void> _pickPhoto() async {
    await ImagePickerSourceSelectionBottomSheet.show<void>(
      context,
      onGalleryPick: () => _handlePhotoPick(ImagePickerUtils.fromGallery),
      onCameraPick: () => _handlePhotoPick(ImagePickerUtils.fromCamera),
    );
  }

  Future<void> _handlePhotoPick(Future<XFile?> Function() pick) async {
    final file = await pick();
    if (file == null || !mounted) {
      return;
    }

    final pickedFile = File(file.path);
    final bytes = await pickedFile.length();
    if (bytes > ProfileEditValidation.maxProfilePhotoBytes) {
      if (!mounted) {
        return;
      }
      context.showVcareToast(
        title: 'Image too large',
        description:
            'Please choose an image under ${ProfileEditValidation.maxProfilePhotoLabel}.',
        variant: VcareToastVariant.warning,
      );
      return;
    }

    setState(() {
      _photoUrl = pickedFile.path;
      _photoCacheKey = null;
    });
  }

  Future<void> _pickDob() async {
    final initial = parseProfileDob(_dob);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(1990, 5, 14),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
  }

  void _removeAddress() {
    setState(() {
      _line1Controller.clear();
      _line2Controller.clear();
      _cityController.clear();
      _stateController.clear();
      _postalCodeController.clear();
      _addressCleared = true;
    });
    if (!mounted) {
      return;
    }
    context.showVcareToast(
      title: 'Address cleared',
      description: 'Save to apply.',
      variant: VcareToastVariant.info,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _primaryCityController.dispose();
    _primaryStateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedAddress = ref.watch(localProfileStateProvider).address;
    final showClear = savedAddress != null && !_addressCleared;
    final dobLabel = _dob.isEmpty ? '' : formatProfileDob(_dob);
    final vcare = context.vcare;

    return Scaffold(
      body: Column(
        children: [
          VcareStickyPageHeader(
            title: 'Edit profile',
            showBack: true,
            action: TextButton(
              onPressed: (_loading || _submitting) ? null : _submit,
              style: TextButton.styleFrom(
                foregroundColor: context.vcare.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: Column(
                              children: [
                                Center(
                                  child: _PhotoSection(
                                    photoUrl: _photoUrl,
                                    photoCacheKey: _photoCacheKey,
                                    fullName: _avatarDisplayName,
                                    onChangePhoto: _pickPhoto,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_showProfileShineNudge) ...[
                                  const _ProfileShineNudge(),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabBarHeaderDelegate(
                            tabBar: TabBar(
                              controller: _tabController,
                              labelColor: context.vcare.foreground,
                              unselectedLabelColor: vcare.mutedForeground,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Your profile'),
                                Tab(text: 'Your story'),
                              ],
                            ),
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _ProfileTab(
                          firstNameController: _firstNameController,
                          middleNameController: _middleNameController,
                          lastNameController: _lastNameController,
                          emailController: _emailController,
                          phoneController: _phoneController,
                          line1Controller: _line1Controller,
                          line2Controller: _line2Controller,
                          cityController: _cityController,
                          stateController: _stateController,
                          postalCodeController: _postalCodeController,
                          primaryCityController: _primaryCityController,
                          primaryStateController: _primaryStateController,
                          gender: _gender,
                          dobLabel: dobLabel,
                          allowTextNotification: _allowTextNotification,
                          errors: _errors,
                          showClear: showClear,
                          phoneCountry: _phoneCountry,
                          onGenderChanged: (value) {
                            setState(() {
                              _gender = value ?? '';
                              _errors = Map<String, String>.from(_errors)
                                ..remove('gender');
                            });
                          },
                          onDobTap: _pickDob,
                          onAllowTextChanged: (value) {
                            setState(() => _allowTextNotification = value);
                          },
                          onClearAddress: _showClearAddressDialog,
                          onAddressPlaceSelected: (parts) {
                            setState(() {
                              _line1Controller.text = parts.line1;
                              _cityController.text = parts.city;
                              _stateController.text = parts.state;
                              _postalCodeController.text = parts.postalCode;
                              _addressCleared = false;
                              _errors = Map<String, String>.from(_errors)
                                ..remove('line1')
                                ..remove('city')
                                ..remove('state')
                                ..remove('postalCode');
                            });
                          },
                          onAddressFieldChanged: () {
                            if (_errors.isEmpty) return;
                            setState(() {
                              _errors = Map<String, String>.from(_errors)
                                ..remove('line1')
                                ..remove('line2')
                                ..remove('city')
                                ..remove('state')
                                ..remove('postalCode');
                            });
                          },
                          onPrimaryChanged: () {
                            if (!_errors.containsKey('primaryCity') &&
                                !_errors.containsKey('primaryState')) {
                              return;
                            }
                            setState(() {
                              _errors = Map<String, String>.from(_errors)
                                ..remove('primaryCity')
                                ..remove('primaryState');
                            });
                          },
                          onNameChanged: () => setState(() {}),
                          onPhoneChanged: () {
                            if (_errors.containsKey('phone')) {
                              setState(
                                () => _errors =
                                    Map<String, String>.from(_errors)
                                      ..remove('phone'),
                              );
                            }
                          },
                        ),
                        SingleChildScrollView(
                          padding: context.mobileShellScrollPadding.copyWith(
                            bottom: context.mobileShellBottomContentPadding +
                                VCareMobileShellInsets.navOuterTop +
                                16,
                          ),
                          child: _BioField(
                            controller: _bioController,
                            errorText: _errors['bio'],
                            onChanged: (_) {
                              setState(() {
                                if (_errors.containsKey('bio')) {
                                  _errors = Map<String, String>.from(_errors)
                                    ..remove('bio');
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearAddressDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear address?'),
        content: const Text(
          'This will clear the address fields. Save changes to apply.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.vcare.destructive,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.trash2, size: 16),
                SizedBox(width: 8),
                Text('Clear'),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeAddress();
    }
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabBarHeaderDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;

  static const _verticalPadding = 8.0;

  @override
  double get minExtent => tabBar.preferredSize.height + (_verticalPadding * 2);

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Child must fill [maxExtent] so layoutExtent never exceeds paintExtent.
    return SizedBox(
      height: maxExtent,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            _verticalPadding,
            20,
            _verticalPadding,
          ),
          child: Material(
            color: context.vcare.muted.withValues(alpha: 0.35),
            borderRadius: VCareRadius.lgAll,
            child: tabBar,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.line1Controller,
    required this.line2Controller,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.primaryCityController,
    required this.primaryStateController,
    required this.gender,
    required this.dobLabel,
    required this.allowTextNotification,
    required this.errors,
    required this.showClear,
    required this.phoneCountry,
    required this.onGenderChanged,
    required this.onDobTap,
    required this.onAllowTextChanged,
    required this.onClearAddress,
    required this.onAddressPlaceSelected,
    required this.onAddressFieldChanged,
    required this.onPrimaryChanged,
    required this.onNameChanged,
    required this.onPhoneChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController line1Controller;
  final TextEditingController line2Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final TextEditingController primaryCityController;
  final TextEditingController primaryStateController;
  final String gender;
  final String dobLabel;
  final bool allowTextNotification;
  final Map<String, String> errors;
  final bool showClear;
  final AuthPhoneCountry phoneCountry;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onDobTap;
  final ValueChanged<bool> onAllowTextChanged;
  final VoidCallback onClearAddress;
  final ValueChanged<ParsedAddressParts> onAddressPlaceSelected;
  final VoidCallback onAddressFieldChanged;
  final VoidCallback onPrimaryChanged;
  final VoidCallback onNameChanged;
  final VoidCallback onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.mobileShellScrollPadding.copyWith(
        bottom: context.mobileShellBottomContentPadding +
            VCareMobileShellInsets.navOuterTop +
            16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProfileField(
                  label: 'First name',
                  isRequired: true,
                  controller: firstNameController,
                  errorText: errors['firstName'],
                  maxLength: 50,
                  onChanged: (_) => onNameChanged(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProfileField(
                  label: 'Last name',
                  isRequired: true,
                  controller: lastNameController,
                  errorText: errors['lastName'],
                  maxLength: 50,
                  onChanged: (_) => onNameChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Middle name',
            controller: middleNameController,
            errorText: errors['middleName'],
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Email',
            isRequired: true,
            controller: emailController,
            errorText: errors['email'],
            keyboardType: TextInputType.emailAddress,
            maxLength: 255,
          ),
          const SizedBox(height: 16),
          _ProfileField(
            label: 'Phone',
            isRequired: true,
            controller: phoneController,
            errorText: errors['phone'],
            keyboardType: TextInputType.phone,
            hint: phoneCountry.hint,
            inputFormatters: [
              AuthNationalPhoneInputFormatter(phoneCountry),
            ],
            prefix: const LoginPhoneCountrySelector(),
            onChanged: (_) => onPhoneChanged(),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => onAllowTextChanged(!allowTextNotification),
            borderRadius: VCareRadius.mdAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: allowTextNotification,
                      onChanged: (value) {
                        onAllowTextChanged(value ?? false);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Allow text notifications',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.vcare.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _GenderField(
                  value: gender,
                  errorText: errors['gender'],
                  onChanged: onGenderChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'Date of birth',
                  value: dobLabel,
                  placeholder: 'Aug 2, 1999',
                  errorText: errors['dob'],
                  onTap: onDobTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AddressSectionHeader(
            showClear: showClear,
            onClear: onClearAddress,
          ),
          const SizedBox(height: 16),
          PrimaryLocationField(
            cityController: primaryCityController,
            stateController: primaryStateController,
            errorText: errors['primaryCity'] ?? errors['primaryState'],
            onChanged: ({required city, required state}) => onPrimaryChanged(),
          ),
          const SizedBox(height: 16),
          _AddressFields(
            line1Controller: line1Controller,
            line2Controller: line2Controller,
            cityController: cityController,
            stateController: stateController,
            postalCodeController: postalCodeController,
            errors: errors,
            onAddressPlaceSelected: onAddressPlaceSelected,
            onFieldChanged: onAddressFieldChanged,
          ),
        ],
      ),
    );
  }
}

class _GenderField extends StatelessWidget {
  const _GenderField({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          hint: Text(
            'Select gender',
            style: TextStyle(color: vcare.mutedForeground),
          ),
          items: [
            for (final option in profileGenderOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
          isExpanded: true,
          decoration: InputDecoration(
            errorText: errorText,
            filled: true,
            fillColor: vcare.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: VCareRadius.xlAll,
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: VCareRadius.xlAll,
              borderSide: BorderSide(color: vcare.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressSectionHeader extends StatelessWidget {
  const _AddressSectionHeader({
    required this.showClear,
    required this.onClear,
  });

  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      children: [
        Icon(LucideIcons.mapPin, size: 14, color: context.vcare.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'ADDRESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: vcare.mutedForeground,
            ),
          ),
        ),
        if (showClear)
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: vcare.mutedForeground,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.eraser, size: 12),
                SizedBox(width: 4),
                Text(
                  'Clear',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddressFields extends StatelessWidget {
  const _AddressFields({
    required this.line1Controller,
    required this.line2Controller,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.errors,
    required this.onAddressPlaceSelected,
    required this.onFieldChanged,
  });

  final TextEditingController line1Controller;
  final TextEditingController line2Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final Map<String, String> errors;
  final ValueChanged<ParsedAddressParts> onAddressPlaceSelected;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddressLine1Autocomplete(
          controller: line1Controller,
          label: 'Address line 1',
          errorText: errors['line1'],
          onChanged: (_) => onFieldChanged(),
          onSelect: onAddressPlaceSelected,
        ),
        const SizedBox(height: 16),
        _ProfileField(
          label: 'Address line 2 (optional)',
          controller: line2Controller,
          hint: 'Apt 4B',
          maxLength: 120,
          errorText: errors['line2'],
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileField(
                label: 'City',
                controller: cityController,
                hint: 'San Francisco',
                maxLength: 80,
                errorText: errors['city'],
                onChanged: (_) => onFieldChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileField(
                label: 'State / Region',
                controller: stateController,
                hint: 'Montana',
                maxLength: 60,
                errorText: errors['state'],
                onChanged: (_) => onFieldChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProfileField(
          label: 'Zip code',
          controller: postalCodeController,
          hint: '94103',
          maxLength: 12,
          errorText: errors['postalCode'],
          onChanged: (_) => onFieldChanged(),
        ),
      ],
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photoUrl,
    this.photoCacheKey,
    required this.fullName,
    required this.onChangePhoto,
  });

  final String? photoUrl;
  final String? photoCacheKey;
  final String fullName;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: VCareRadius.xxlAll,
            border: Border.all(color: vcare.border),
          ),
          child: ProfileAvatar(
            name: fullName,
            photoUrl: photoUrl,
            photoCacheKey: photoCacheKey,
            size: 96,
            borderRadius: 24,
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: context.vcare.primary,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onChangePhoto,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  LucideIcons.camera,
                  size: 16,
                  color: context.theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileShineNudge extends StatelessWidget {
  const _ProfileShineNudge();

  static const _amber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.1),
        borderRadius: VCareRadius.xlAll,
        border: Border.all(color: _amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.info, size: 16, color: _amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Strengthen your profile with a photo and bio. This will be '
              'reflected in your profile page.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: context.vcare.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioField extends StatelessWidget {
  const _BioField({
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final length = controller.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About you (optional)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: ProfileEditValidation.maxBioLength,
          minLines: 4,
          maxLines: 6,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Share a short intro clients will see on your profile.',
            errorText: errorText,
            filled: true,
            fillColor: vcare.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: VCareRadius.xlAll,
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: VCareRadius.xlAll,
              borderSide: BorderSide(color: vcare.border),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                errorText == null
                    ? 'Shown on your public profile and referral page.'
                    : '',
                style: TextStyle(fontSize: 12, color: vcare.mutedForeground),
              ),
            ),
            Text(
              '$length/${ProfileEditValidation.maxBioLength}',
              style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.isRequired = false,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.prefix,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.vcare.foreground,
                ),
              ),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.vcare.destructive,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            errorText: errorText,
            filled: true,
            fillColor: vcare.card,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            prefixIcon: prefix,
            prefixIconConstraints: prefix == null
                ? null
                : const BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
              borderRadius: VCareRadius.xlAll,
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: VCareRadius.xlAll,
              borderSide: BorderSide(color: vcare.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? placeholder;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: VCareRadius.xlAll,
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              filled: true,
              fillColor: vcare.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              suffixIcon: Icon(
                LucideIcons.calendar,
                size: 16,
                color: vcare.mutedForeground,
              ),
              border: OutlineInputBorder(
                borderRadius: VCareRadius.xlAll,
                borderSide: BorderSide(color: vcare.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: VCareRadius.xlAll,
                borderSide: BorderSide(color: vcare.border),
              ),
            ),
            child: Text(
              value.isEmpty ? (placeholder ?? '') : value,
              style: TextStyle(
                color: value.isEmpty ? vcare.mutedForeground : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
