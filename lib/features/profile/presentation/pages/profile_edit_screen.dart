import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/features/profile/domain/entities/profile_address.dart';
import 'package:vcare_admin/features/profile/presentation/providers/local_profile_state_provider.dart';
import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/widgets/common_image.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.addressOnly = false});

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
  Map<String, String> _errors = {};

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromProfile());
  }

  void _loadFromProfile() {
    final profile = ref.read(localProfileStateProvider);
    _applyProfile(profile);
  }

  void _applyProfile(LocalProfile profile) {
    final address = profile.address;
    setState(() {
      _fullNameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _dob = profile.dob;
      _photoUrl = profile.photoUrl;
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
      validatePersonalInfo: !widget.addressOnly,
    );
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() => _errors = {});

    final notifier = ref.read(localProfileStateProvider.notifier);
    if (widget.addressOnly) {
      await notifier.updateAddress(_addressFromForm(form));
    } else {
      await notifier.updatePersonalInfo(
        fullName: form.fullName.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        dob: form.dob.trim(),
        photoUrl: _photoUrl,
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image too large. Please choose an image under 5MB.'),
        ),
      );
      return;
    }

    setState(() => _photoUrl = pickedFile.path);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address cleared. Save to apply.')),
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
    final parsedDob = parseProfileDob(_dob);
    final dobLabel = parsedDob == null
        ? 'Select date of birth'
        : DateFormat('MMM d, yyyy').format(parsedDob);

    return Scaffold(
      body: Column(
        children: [
          VcarePageHeader(
            title: widget.addressOnly ? 'Address' : 'Edit profile',
            subtitle: widget.addressOnly
                ? 'Where VCare should send care updates'
                : 'Keep your personal information current',
            showBack: true,
            action: TextButton(
              onPressed: _submit,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.addressOnly) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: _PhotoSection(
                        photoUrl: _photoUrl,
                        initials: profileInitials(_fullNameController.text),
                        onChangePhoto: _pickPhoto,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading('Personal info'),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Full name',
                      controller: _fullNameController,
                      errorText: _errors['fullName'],
                      maxLength: 80,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Date of birth',
                      value: dobLabel,
                      errorText: _errors['dob'],
                      onTap: _pickDob,
                    ),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Email',
                      controller: _emailController,
                      errorText: _errors['email'],
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 255,
                    ),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Phone',
                      controller: _phoneController,
                      errorText: _errors['phone'],
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                    ),
                  ],
                  if (!widget.addressOnly) const SizedBox(height: 24),
                  if (widget.addressOnly) ...[
                    const _SectionHeading('Home address'),
                    const SizedBox(height: 12),
                    _AddressFields(
                      line1Controller: _line1Controller,
                      line2Controller: _line2Controller,
                      cityController: _cityController,
                      stateController: _stateController,
                      postalCodeController: _postalCodeController,
                      countryController: _countryController,
                      errors: _errors,
                      savedAddress: savedAddress,
                      onClear: _showClearAddressDialog,
                    ),
                  ],
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _removeAddress();
    }
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
    required this.savedAddress,
    required this.onClear,
  });

  final TextEditingController line1Controller;
  final TextEditingController line2Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final TextEditingController countryController;
  final Map<String, String> errors;
  final ProfileAddress? savedAddress;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (savedAddress != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
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
          ),
        _ProfileField(
          label: 'Street address',
          controller: line1Controller,
          hint: '123 Market St',
          maxLength: 120,
          errorText: errors['line1'],
        ),
        const SizedBox(height: 12),
        _ProfileField(
          label: 'Apt, suite, etc. (optional)',
          controller: line2Controller,
          hint: 'Apt 4B',
          maxLength: 120,
          errorText: errors['line2'],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
    required this.initials,
    required this.onChangePhoto,
  });

  final String? photoUrl;
  final String initials;
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
          decoration: BoxDecoration(
            color: vcare.muted,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: vcare.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl == null
              ? Center(
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: vcare.mutedForeground,
                    ),
                  ),
                )
              : _ProfilePhoto(photoUrl: photoUrl!),
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

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.startsWith('assets/')) {
      return CommonImage(
        assetsOrUrlOrPath: photoUrl,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      );
    }
    return Image.file(File(photoUrl), fit: BoxFit.cover, width: 96, height: 96);
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
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final int? maxLength;
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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            errorText: errorText,
            filled: true,
            fillColor: vcare.card,
            isDense: true,
            contentPadding: const EdgeInsets.all(14),
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
    this.errorText,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
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
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              filled: true,
              fillColor: vcare.card,
              contentPadding: const EdgeInsets.all(14),
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
            child: Text(value),
          ),
        ),
      ],
    );
  }
}
