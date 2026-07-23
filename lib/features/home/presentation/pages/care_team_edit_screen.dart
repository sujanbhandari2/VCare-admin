import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/auth_national_phone_input_formatter.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/auth/domain/auth_phone_validator.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/features/auth/presentation/widgets/login_phone_country_selector.dart';
import 'package:vcare_admin/features/care_team/domain/entities/care_team_member.dart';
import 'package:vcare_admin/features/care_team/presentation/providers/care_team_state_provider.dart';
import 'package:vcare_admin/features/home/utils/care_team_utils.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/field_validator.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_sticky_tab_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_success_drawer.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

const _maxPhotoBytes = 5 * 1024 * 1024;
const _fieldGap = 20.0;
const _labelGap = 8.0;
const _fieldRadius = 12.0;

class CareTeamEditScreen extends ConsumerStatefulWidget {
  const CareTeamEditScreen({super.key, this.memberId});

  final String? memberId;

  @override
  ConsumerState<CareTeamEditScreen> createState() => _CareTeamEditScreenState();
}

class _CareTeamEditScreenState extends ConsumerState<CareTeamEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _groupNumberController = TextEditingController();

  CareTeamRole _role = CareTeamRole.advocate;
  static const _phoneCountry = AuthPhoneCountry.usa;
  String? _photoUrl;
  bool _loading = true;
  bool _submitting = false;
  Map<String, String> _fieldErrors = {};

  bool get _isEdit => widget.memberId != null;

  bool get _showOrgFields => isCareTeamOrgRole(_role);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMember());
  }

  void _loadMember() {
    if (!_isEdit) {
      setState(() => _loading = false);
      return;
    }

    final member =
        ref.read(careTeamStateProvider.notifier).byId(widget.memberId!);
    if (member == null) {
      if (mounted) {
        context.goNamed(AppRouter.careTeamName);
      }
      return;
    }

    if (isCareTeamSystemContact(member.id)) {
      if (mounted) {
        context.goNamed(
          AppRouter.careTeamDetailName,
          pathParameters: {'id': member.id},
        );
      }
      return;
    }

    final rawPhone = member.phone ?? '';
    final nationalDigits = AuthPhoneFormatter.toDisplayDigits(
      rawPhone,
      fallback: _phoneCountry,
    );

    setState(() {
      _nameController.text = member.name;
      _role = member.role;
      _emailController.text = member.email ?? '';
      _phoneController.text = AuthPhoneFormatter.formatNationalDisplay(
        nationalDigits,
        _phoneCountry,
      );
      _websiteController.text = member.website ?? '';
      _bioController.text = member.bio ?? '';
      _addressController.text = member.address ?? '';
      _policyNumberController.text = member.policyNumber ?? '';
      _groupNumberController.text = member.groupNumber ?? '';
      _photoUrl = member.photoUrl ?? member.photoAsset;
      _loading = false;
    });
  }

  void _clearFieldError(String key) {
    if (!_fieldErrors.containsKey(key)) return;
    setState(() {
      _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(key);
    });
  }

  bool _validateFields() {
    final errors = <String, String>{};

    if (!careTeamRoles.contains(_role)) {
      errors['role'] = 'Role is required';
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.length > 80) {
      errors['name'] = 'Name must be 80 characters or less';
    } else if (RegExp(r'\d').hasMatch(name)) {
      errors['name'] = 'Name cannot contain numbers';
    } else if (!RegExp(r"^[a-zA-Z][a-zA-Z .'\-]*$").hasMatch(name)) {
      errors['name'] = 'Enter a valid name';
    }

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isNotEmpty) {
      final phoneError = AuthPhoneValidator.validate(
        _phoneController.text,
        country: _phoneCountry,
        context: context,
      );
      if (phoneError != null) {
        errors['phone'] = phoneError;
      }
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      final emailError = FieldValidator.validateEmail(
        email,
        context: context,
      );
      if (emailError != null) {
        errors['email'] = emailError;
      }
    }

    final website = _websiteController.text.trim();
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      final isValidHttpUrl = uri != null &&
          uri.hasScheme &&
          (uri.isScheme('http') || uri.isScheme('https')) &&
          uri.host.isNotEmpty;
      if (!isValidHttpUrl) {
        errors['website'] = 'Enter a valid website URL (http:// or https://)';
      }
    }

    if (_bioController.text.trim().length > 500) {
      errors['notes'] = 'Notes must be 500 characters or less';
    }

    setState(() => _fieldErrors = errors);
    return errors.isEmpty;
  }

  String get _composedPhone => AuthPhoneFormatter.toApiDigits(
        _phoneCountry.dialCode,
        _phoneController.text,
      );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _policyNumberController.dispose();
    _groupNumberController.dispose();
    super.dispose();
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
    if (file == null || !mounted) return;

    final bytes = await file.length();
    if (bytes > _maxPhotoBytes) {
      if (!mounted) return;
      context.showVcareToast(
        title: 'Image too large',
        description: 'Max 5MB.',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    setState(() => _photoUrl = file.path);
  }

  Future<void> _save() async {
    if (!_validateFields()) {
      return;
    }

    setState(() => _submitting = true);

    final input = (
      name: _nameController.text.trim(),
      role: _role,
      email: _emailController.text.trim(),
      phone: _composedPhone,
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      bio: _bioController.text.trim(),
      photoUrl: _photoUrl,
      address: _showOrgFields && _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      policyNumber:
          _showOrgFields && _policyNumberController.text.trim().isNotEmpty
              ? _policyNumberController.text.trim()
              : null,
      groupNumber:
          _showOrgFields && _groupNumberController.text.trim().isNotEmpty
              ? _groupNumberController.text.trim()
              : null,
    );

    final notifier = ref.read(careTeamStateProvider.notifier);
    if (_isEdit) {
      notifier.update(widget.memberId!, input);
      if (!mounted) return;
      setState(() => _submitting = false);

      await showVcareSuccessDrawer(
        context: context,
        title: 'Contact saved',
        description: 'Your changes have been saved.',
        onAction: () {
          if (mounted) {
            context.goNamed(AppRouter.careTeamName);
          }
        },
      );
      return;
    }

    CareTeamMember? created;
    await notifier.createContact(
      input,
      onCompleted: (member) => created = member,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (created == null) {
      final error = ref.read(careTeamStateProvider).createError;
      context.showVcareToast(
        title: 'Could not add contact',
        description: error ?? 'Something went wrong. Please try again.',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    await showVcareSuccessDrawer(
      context: context,
      title: 'Contact added',
      description: 'The contact was added to your care team.',
      onAction: () {
        if (mounted) {
          context.goNamed(AppRouter.careTeamName);
        }
      },
    );
  }

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove contact?'),
        content: const Text(
          'This contact will be removed from your care team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: VCareColors.destructive),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ref.read(careTeamStateProvider.notifier).remove(widget.memberId!);
    if (!mounted) return;

    context.showVcareToast(
      title: 'Removed',
      variant: VcareToastVariant.success,
    );
    context.goNamed(AppRouter.careTeamName);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initials = careTeamInitials(_nameController.text);
    final safeTop = MediaQuery.paddingOf(context).top;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: VcarePinnedPageTitleDelegate(
              safeTop: safeTop,
              textScaleFactor: textScaleFactor,
              hasSubtitle: false,
              title: vcareTabPageTitle(
                title: _isEdit ? 'Edit contact' : 'Add contact',
                showBack: true,
                action: VcareHeaderActionButton(
                  label: 'Save',
                  loading: _submitting,
                  onPressed: _submitting ? null : _save,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: context.mobileShellScrollPadding.copyWith(top: 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),
                _PhotoSection(
                  photoUrl: _photoUrl,
                  initials: initials,
                  onChangePhoto: _pickPhoto,
                  onRemovePhoto: _photoUrl == null
                      ? null
                      : () => setState(() => _photoUrl = null),
                ),
                const SizedBox(height: _fieldGap),
                _CareTeamField(
                  label: 'Role',
                  errorText: _fieldErrors['role'],
                  child: _RoleDropdown(
                    value: _role,
                    hasError: _fieldErrors.containsKey('role'),
                    onChanged: (role) {
                      _clearFieldError('role');
                      setState(() => _role = role);
                    },
                  ),
                ),
                const SizedBox(height: _fieldGap),
                _CareTeamField(
                  label: 'Name',
                  errorText: _fieldErrors['name'],
                  child: TextField(
                    controller: _nameController,
                    maxLength: 80,
                    style: _CareTeamFormTypography.input(context),
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\d')),
                    ],
                    onChanged: (_) {
                      _clearFieldError('name');
                      setState(() {});
                    },
                    decoration: _inputDecoration(
                      context,
                      hintText: 'Full name',
                      hasError: _fieldErrors.containsKey('name'),
                    ),
                  ),
                ),
                const SizedBox(height: _fieldGap),
                _CareTeamField(
                  label: 'Phone',
                  errorText: _fieldErrors['phone'],
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: _CareTeamFormTypography.input(context),
                    inputFormatters: [
                      AuthNationalPhoneInputFormatter(_phoneCountry),
                    ],
                    onChanged: (_) => _clearFieldError('phone'),
                    decoration: _inputDecoration(
                      context,
                      hintText: _phoneCountry.hint,
                      hasError: _fieldErrors.containsKey('phone'),
                      prefixIcon: const LoginPhoneCountrySelector(),
                    ),
                  ),
                ),
                const SizedBox(height: _fieldGap),
                _CareTeamField(
                  label: 'Email',
                  errorText: _fieldErrors['email'],
                  child: TextField(
                    controller: _emailController,
                    maxLength: 255,
                    keyboardType: TextInputType.emailAddress,
                    style: _CareTeamFormTypography.input(context),
                    onChanged: (_) => _clearFieldError('email'),
                    decoration: _inputDecoration(
                      context,
                      hintText: 'name@example.com',
                      hasError: _fieldErrors.containsKey('email'),
                    ),
                  ),
                ),
                const SizedBox(height: _fieldGap),
                _CareTeamField(
                  label: 'Website',
                  errorText: _fieldErrors['website'],
                  child: TextField(
                    controller: _websiteController,
                    maxLength: 255,
                    keyboardType: TextInputType.url,
                    style: _CareTeamFormTypography.input(context),
                    onChanged: (_) => _clearFieldError('website'),
                    decoration: _inputDecoration(
                      context,
                      hintText: 'https://',
                      hasError: _fieldErrors.containsKey('website'),
                    ),
                  ),
                ),
                if (_showOrgFields) ...[
                  const SizedBox(height: _fieldGap),
                  _CareTeamField(
                    label: 'Address',
                    child: TextField(
                      controller: _addressController,
                      maxLength: 200,
                      style: _CareTeamFormTypography.input(context),
                      decoration: _inputDecoration(
                        context,
                        hintText: 'Street, City, State',
                      ),
                    ),
                  ),
                  const SizedBox(height: _fieldGap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CareTeamField(
                          label: 'Policy #',
                          child: TextField(
                            controller: _policyNumberController,
                            maxLength: 60,
                            style: _CareTeamFormTypography.input(context),
                            decoration: _inputDecoration(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CareTeamField(
                          label: 'Group #',
                          child: TextField(
                            controller: _groupNumberController,
                            maxLength: 60,
                            style: _CareTeamFormTypography.input(context),
                            decoration: _inputDecoration(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: _fieldGap),
                _CareTeamField(
                  label: 'Notes',
                  errorText: _fieldErrors['notes'],
                  child: TextField(
                    controller: _bioController,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 5,
                    style: _CareTeamFormTypography.input(context),
                    onChanged: (_) => _clearFieldError('notes'),
                    decoration: _inputDecoration(
                      context,
                      hintText: 'Add notes about this contact',
                      hasError: _fieldErrors.containsKey('notes'),
                    ),
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: _fieldGap),
                  OutlinedButton.icon(
                    onPressed: _confirmRemove,
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: VCareColors.destructive,
                    ),
                    label: Text(
                      'Remove contact',
                      style: context.textTheme.semibold14?.copyWith(
                        color: VCareColors.destructive,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: context.vcare.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: context.vcare.border),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  String? hintText,
  Widget? prefixIcon,
  bool hasError = false,
}) {
  final vcare = context.vcare;
  final borderColor = hasError ? VCareColors.destructive : vcare.border;
  final focusedColor =
      hasError ? VCareColors.destructive : VCareColors.primary;

  return InputDecoration(
    hintText: hintText,
    hintStyle: _CareTeamFormTypography.hint(context),
    counterText: '',
    filled: true,
    fillColor: Theme.of(context).scaffoldBackgroundColor,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(
      horizontal: prefixIcon == null ? 12 : 8,
      vertical: 12,
    ),
    prefixIcon: prefixIcon,
    prefixIconConstraints: prefixIcon == null
        ? null
        : const BoxConstraints(minWidth: 0, minHeight: 0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: focusedColor, width: 1.5),
    ),
  );
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photoUrl,
    required this.initials,
    required this.onChangePhoto,
    this.onRemovePhoto,
  });

  final String? photoUrl;
  final String initials;
  final VoidCallback onChangePhoto;
  final VoidCallback? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: vcare.muted,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? _ContactPhoto(url: photoUrl!, initials: initials)
                  : _PhotoPlaceholder(initials: initials),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Material(
                color: VCareColors.primary,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onChangePhoto,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      size: 14,
                      color: VCareColors.primaryForeground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (onRemovePhoto != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRemovePhoto,
            style: TextButton.styleFrom(
              foregroundColor: vcare.mutedForeground,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Remove photo',
              style: context.textTheme.regular12?.copyWith(
                color: vcare.mutedForeground,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactPhoto extends StatelessWidget {
  const _ContactPhoto({required this.url, required this.initials});

  final String url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http')) {
      return VCareCachedImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: _PhotoPlaceholder(initials: initials),
      );
    }
    if (File(url).existsSync()) {
      return Image.file(File(url), fit: BoxFit.cover);
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _PhotoPlaceholder(initials: initials),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    return Center(
      child: initials.isEmpty
          ? Icon(LucideIcons.camera, size: 24, color: vcare.mutedForeground)
          : Text(
              initials,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: vcare.mutedForeground,
              ),
            ),
    );
  }
}

class _CareTeamField extends StatelessWidget {
  const _CareTeamField({
    required this.label,
    required this.child,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _CareTeamFormTypography.label(context),
        ),
        const SizedBox(height: _labelGap),
        child,
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: context.textTheme.regular12?.copyWith(
                  color: VCareColors.destructive,
                ) ??
                TextStyle(
                  fontSize: 12,
                  color: VCareColors.destructive,
                ),
          ),
        ],
      ],
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final CareTeamRole value;
  final ValueChanged<CareTeamRole> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return DropdownButtonFormField<CareTeamRole>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(_fieldRadius),
      style: _CareTeamFormTypography.select(context),
      icon: Icon(
        LucideIcons.chevronDown,
        size: 16,
        color: vcare.mutedForeground.withValues(alpha: 0.7),
      ),
      decoration: _inputDecoration(context, hasError: hasError),
      items: [
        for (final role in careTeamRoles)
          DropdownMenuItem(
            value: role,
            child: Text(
              careTeamRoleLabel(role),
              style: _CareTeamFormTypography.select(context),
            ),
          ),
      ],
      onChanged: (role) {
        if (role != null) onChanged(role);
      },
    );
  }
}

abstract final class _CareTeamFormTypography {
  static TextStyle label(BuildContext context) {
    return context.textTheme.medium14?.copyWith(
          color: context.theme.colorScheme.onSurface,
          height: 1,
        ) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  }

  static TextStyle input(BuildContext context) {
    return context.textTheme.regular16?.copyWith(
          color: context.theme.colorScheme.onSurface,
          height: 1.25,
        ) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  }

  static TextStyle select(BuildContext context) {
    return context.textTheme.regular14?.copyWith(
          color: context.theme.colorScheme.onSurface,
          height: 1.25,
        ) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  }

  static TextStyle hint(BuildContext context) {
    return context.textTheme.regular14?.copyWith(
          color: context.vcare.mutedForeground,
          height: 1.25,
        ) ??
        TextStyle(
          fontSize: 14,
          color: context.vcare.mutedForeground,
        );
  }
}
