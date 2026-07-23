import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/auth_national_phone_input_formatter.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_validator.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_phone_country_selector.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/presentation/providers/auth_me_state_provider.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.addressOnly = false});

  /// Kept for route parity with vcareapp `/profile/address` — same full form.
  final bool addressOnly;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;

  String _dob = '';
  String? _photoUrl;
  String? _photoCacheKey;
  static const _phoneCountry = AuthPhoneCountry.usa;
  Map<String, String> _errors = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _line1Controller = TextEditingController();
    _line2Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController(text: 'United States');

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
    setState(() {
      _fullNameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = AuthPhoneFormatter.formatNationalDisplay(
        displayDigits,
        _phoneCountry,
      );
      _dob = profileDobToIso(profile.dob);
      _photoUrl = profile.photoUrl;
      _photoCacheKey = profile.photoCacheKey;
      _line1Controller.text = address?.line1 ?? '';
      _line2Controller.text = address?.line2 ?? '';
      _cityController.text = address?.city ?? '';
      _stateController.text = address?.state ?? '';
      _postalCodeController.text = address?.postalCode ?? '';
      _countryController.text = address?.country ?? 'United States';
    });
  }

  ProfileEditFormData _currentForm() {
    return ProfileEditFormData(
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      dob: _dob,
      line1: _line1Controller.text,
      line2: _line2Controller.text,
      city: _cityController.text,
      state: _stateController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
    );
  }

  ProfileAddress? _addressFromForm(ProfileEditFormData form) {
    final hasAddress =
        form.line1.trim().isNotEmpty &&
        form.city.trim().isNotEmpty &&
        form.state.trim().isNotEmpty &&
        form.postalCode.trim().isNotEmpty &&
        form.country.trim().isNotEmpty;
    if (!hasAddress) {
      return null;
    }
    return ProfileAddress(
      line1: form.line1.trim(),
      line2: form.line2.trim().isEmpty ? null : form.line2.trim(),
      city: form.city.trim(),
      state: form.state.trim(),
      postalCode: form.postalCode.trim(),
      country: form.country.trim(),
    );
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

    final updated = await ref.read(authMeStateProvider.notifier).updateMe(
          fullName: form.fullName.trim(),
          email: form.email.trim(),
          phone: phoneForApi,
          dateOfBirth: form.dob.trim(),
          photoUrl: _photoUrl,
          address: _addressFromForm(form),
        );

    if (!mounted) {
      return;
    }

    if (!updated) {
      final error = ref.read(authMeStateProvider).error;
      setState(() => _submitting = false);
      context.showVcareToast(
        title: error ?? 'Failed to update profile.',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    setState(() => _submitting = false);
    context.showVcareToast(
      title: 'Profile updated',
      variant: VcareToastVariant.success,
    );
    context.pop();
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
      _countryController.text = 'United States';
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedAddress = ref.watch(localProfileStateProvider).address;
    final dobLabel = _dob.isEmpty ? '' : formatProfileDob(_dob);

    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(
            title: 'Edit profile',
            showBack: true,
            action: TextButton(
              onPressed: (_loading || _submitting) ? null : _submit,
              style: TextButton.styleFrom(
                foregroundColor: VCareColors.primary,
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
                : SingleChildScrollView(
              padding: context.mobileShellScrollPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  Center(
                    child: _PhotoSection(
                      photoUrl: _photoUrl,
                      photoCacheKey: _photoCacheKey,
                      fullName: _fullNameController.text,
                      onChangePhoto: _pickPhoto,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeading('Personal info'),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Full name',
                    controller: _fullNameController,
                    errorText: _errors['fullName'],
                    maxLength: 80,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: 'Date of birth',
                    value: dobLabel,
                    placeholder: 'MM/DD/YYYY',
                    errorText: _errors['dob'],
                    onTap: _pickDob,
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Email',
                    controller: _emailController,
                    errorText: _errors['email'],
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 255,
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Phone',
                    controller: _phoneController,
                    errorText: _errors['phone'],
                    keyboardType: TextInputType.phone,
                    hint: _phoneCountry.hint,
                    inputFormatters: [
                      AuthNationalPhoneInputFormatter(_phoneCountry),
                    ],
                    prefix: const LoginPhoneCountrySelector(),
                    onChanged: (_) {
                      if (_errors.containsKey('phone')) {
                        setState(
                          () => _errors =
                              Map<String, String>.from(_errors)..remove('phone'),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _AddressSectionHeader(
                    savedAddress: savedAddress,
                    onClear: _showClearAddressDialog,
                  ),
                  const SizedBox(height: 16),
                  _AddressFields(
                    line1Controller: _line1Controller,
                    line2Controller: _line2Controller,
                    cityController: _cityController,
                    stateController: _stateController,
                    postalCodeController: _postalCodeController,
                    countryController: _countryController,
                    errors: _errors,
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
              backgroundColor: VCareColors.destructive,
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

class _AddressSectionHeader extends StatelessWidget {
  const _AddressSectionHeader({
    required this.savedAddress,
    required this.onClear,
  });

  final ProfileAddress? savedAddress;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Row(
      children: [
        Icon(LucideIcons.mapPin, size: 14, color: VCareColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'HOME ADDRESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: vcare.mutedForeground,
            ),
          ),
        ),
        if (savedAddress != null)
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: VCareColors.destructive,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Clear',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    required this.countryController,
    required this.errors,
  });

  final TextEditingController line1Controller;
  final TextEditingController line2Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final TextEditingController countryController;
  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileField(
          label: 'Street address',
          controller: line1Controller,
          hint: '123 Market St',
          maxLength: 120,
          errorText: errors['line1'],
        ),
        const SizedBox(height: 16),
        _ProfileField(
          label: 'Apt, suite, etc. (optional)',
          controller: line2Controller,
          hint: 'Apt 4B',
          maxLength: 120,
          errorText: errors['line2'],
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
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileField(
                label: 'State / Region',
                controller: stateController,
                hint: 'CA',
                maxLength: 60,
                errorText: errors['state'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileField(
                label: 'Postal code',
                controller: postalCodeController,
                hint: '94103',
                maxLength: 12,
                errorText: errors['postalCode'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileField(
                label: 'Country',
                controller: countryController,
                hint: 'United States',
                maxLength: 60,
                errorText: errors['country'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Fill all address fields to save. Used for shipping ID cards and finding nearby care.',
          style: TextStyle(fontSize: 11, color: vcare.mutedForeground),
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
            borderRadius: BorderRadius.circular(24),
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
            color: VCareColors.primary,
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
                  color: VCareColors.primaryForeground,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: context.vcare.mutedForeground,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
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
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: vcare.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: vcare.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
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
