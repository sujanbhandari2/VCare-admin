import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/app_theme.dart';
import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/presentation/providers/family_members_state_provider.dart';
import 'package:vcare_admin/features/profile/utils/family_member_edit_utils.dart';
import 'package:vcare_admin/features/profile/utils/family_member_edit_validation.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';
import 'package:vcare_admin/shared/widgets/vcare_page_header.dart';
import 'package:vcare_admin/shared/widgets/vcare_success_drawer.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

class FamilyMemberEditScreen extends ConsumerStatefulWidget {
  const FamilyMemberEditScreen({super.key, this.memberId});

  final String? memberId;

  @override
  ConsumerState<FamilyMemberEditScreen> createState() =>
      _FamilyMemberEditScreenState();
}

class _FamilyMemberEditScreenState extends ConsumerState<FamilyMemberEditScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _relationship = '';
  String _gender = '';
  String _dobMonth = '';
  String _dobDay = '';
  String _dobYear = '';
  String? _photoUrl;
  Map<String, String> _errors = {};
  bool _loading = true;
  bool _submitting = false;
  bool _deleting = false;

  bool get _isEdit => widget.memberId != null;

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

    final member = ref.read(familyMembersStateProvider.notifier).byId(widget.memberId!);
    if (member == null) {
      if (mounted) {
        context.go('/profile');
      }
      return;
    }

    final dob = fromIsoDob(member.dateOfBirth);
    setState(() {
      _nameController.text = member.fullName;
      _relationship = member.relationship;
      _gender = member.gender ?? '';
      _dobMonth = dob.month;
      _dobDay = dob.day;
      _dobYear = dob.year;
      _photoUrl = member.photoUrl;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    if (file == null || !mounted) {
      return;
    }

    final pickedFile = File(file.path);
    final bytes = await pickedFile.length();
    if (bytes > maxProfilePhotoBytes) {
      if (!mounted) {
        return;
      }
      context.showVcareToast(
        title: 'Image too large',
        description: 'Please choose an image under $maxProfilePhotoLabel.',
        variant: VcareToastVariant.warning,
      );
      return;
    }

    setState(() => _photoUrl = pickedFile.path);
  }

  Future<void> _submit() async {
    final dob = toIsoDob(_dobMonth, _dobDay, _dobYear);
    final form = FamilyMemberFormData(
      name: _nameController.text,
      relationship: _relationship,
      gender: _gender,
      dob: dob,
    );
    final errors = FamilyMemberEditValidation.validate(form);
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _errors = {};
      _submitting = true;
    });

    final notifier = ref.read(familyMembersStateProvider.notifier);
    final payload = (
      name: form.name.trim(),
      relationship: form.relationship,
      gender: form.gender,
      dob: form.dob,
      photoUrl: _photoUrl,
    );

    final saved = _isEdit
        ? await notifier.updateFamilyMember(
            id: widget.memberId!,
            name: payload.name,
            relationship: payload.relationship,
            gender: payload.gender,
            dob: payload.dob,
            photoUrl: payload.photoUrl,
          )
        : await notifier.createFamilyMember(
            name: payload.name,
            relationship: payload.relationship,
            gender: payload.gender,
            dob: payload.dob,
            photoUrl: payload.photoUrl,
          );

    if (!mounted) return;

    if (!saved) {
      final error = ref.read(familyMembersStateProvider).error;
      setState(() => _submitting = false);
      context.showVcareToast(
        title: error ??
            (_isEdit
                ? 'Failed to save family member.'
                : 'Failed to add family member.'),
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    setState(() => _submitting = false);
    _showSuccessDrawer(saved: _isEdit);
  }

  Future<void> _showSuccessDrawer({required bool saved}) async {
    await showVcareSuccessDrawer(
      context: context,
      title: saved ? 'Member saved' : 'Member added',
      description: saved
          ? 'Family member details were saved.'
          : 'Family member was added.',
      onAction: () {
        if (mounted) {
          context.pop();
        }
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove family member?'),
        content: Text(
          '${_nameController.text.trim()} will be removed from your family list.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deleting = true);

    final deleted = await ref
        .read(familyMembersStateProvider.notifier)
        .deleteFamilyMember(id: widget.memberId!);

    if (!mounted) {
      return;
    }

    if (!deleted) {
      final error = ref.read(familyMembersStateProvider).error;
      setState(() => _deleting = false);
      context.showVcareToast(
        title: 'Could not remove member',
        description: error ?? 'Failed to remove family member.',
        variant: VcareToastVariant.destructive,
      );
      return;
    }

    setState(() => _deleting = false);
    context.showVcareToast(
      title: 'Removed',
      description: '${_nameController.text.trim()} was removed.',
      variant: VcareToastVariant.success,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          VcareStickyPageHeader(
            title: _isEdit ? 'Edit family member' : 'Add family member',
            showBack: true,
            onBack: () => context.pop(),
            action: VcareHeaderActionButton(
              label: 'Save',
              loading: _submitting,
              onPressed: _loading || _submitting || _deleting ? null : _submit,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: context.mobileShellScrollPadding,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: _PhotoSection(
                              photoUrl: _photoUrl,
                              name: _nameController.text,
                              onChangePhoto: _pickPhoto,
                              onRemovePhoto: _photoUrl == null
                                  ? null
                                  : () => setState(() => _photoUrl = null),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FamilyField(
                            label: 'Full name',
                            child: TextField(
                              controller: _nameController,
                              maxLength: 80,
                              style: _FamilyFormTypography.input(context),
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(
                                context,
                                hintText: 'e.g. Jordan Rivera',
                                errorText: _errors['name'],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FamilyField(
                            label: 'Relationship',
                            child: _FamilyDropdown(
                              value: _relationship,
                              hint: 'Select relationship',
                              stringItems: relationshipOptions,
                              errorText: _errors['relationship'],
                              onChanged: (value) =>
                                  setState(() => _relationship = value ?? ''),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FamilyField(
                            label: 'Gender',
                            child: _FamilyDropdown(
                              value: _gender,
                              hint: 'Select gender',
                              stringItems: genderOptions,
                              errorText: _errors['gender'],
                              onChanged: (value) =>
                                  setState(() => _gender = value ?? ''),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FamilyField(
                            label: 'Date of birth',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 14,
                                      child: _FamilyDropdown(
                                        value: _dobMonth,
                                        hint: 'Month',
                                        options: [
                                          for (var i = 0; i < dobMonths.length; i++)
                                            _DropdownOption(
                                              (i + 1).toString(),
                                              dobMonths[i],
                                            ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _dobMonth = value ?? '';
                                            final maxDays = daysInMonth(
                                              _dobMonth,
                                              _dobYear,
                                            );
                                            if (int.tryParse(_dobDay) != null &&
                                                int.parse(_dobDay) > maxDays) {
                                              _dobDay = '';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 10,
                                      child: _FamilyDropdown(
                                        value: _dobDay,
                                        hint: 'Day',
                                        options: [
                                          for (var day = 1;
                                              day <=
                                                  daysInMonth(
                                                    _dobMonth,
                                                    _dobYear,
                                                  );
                                              day++)
                                            _DropdownOption(
                                              day.toString(),
                                              day.toString(),
                                            ),
                                        ],
                                        onChanged: (value) =>
                                            setState(() => _dobDay = value ?? ''),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 11,
                                      child: _FamilyDropdown(
                                        value: _dobYear,
                                        hint: 'Year',
                                        options: [
                                          for (final year in dobYears())
                                            _DropdownOption(
                                              year.toString(),
                                              year.toString(),
                                            ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _dobYear = value ?? '';
                                            final maxDays = daysInMonth(
                                              _dobMonth,
                                              _dobYear,
                                            );
                                            if (int.tryParse(_dobDay) != null &&
                                                int.parse(_dobDay) > maxDays) {
                                              _dobDay = '';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (_errors['dob'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _errors['dob']!,
                                    style: _FamilyFormTypography.error(context),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 28),
                            OutlinedButton.icon(
                              onPressed: _deleting || _submitting ? null : _confirmDelete,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: VCareColors.destructive,
                                textStyle: context.textTheme.semibold14,
                                side: BorderSide(
                                  color: VCareColors.destructive.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _deleting
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: VCareColors.destructive,
                                      ),
                                    )
                                  : const Icon(LucideIcons.trash2, size: 16),
                              label: Text(
                                _deleting ? 'Removing...' : 'Remove member',
                              ),
                            ),
                          ],
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

InputDecoration _inputDecoration(
  BuildContext context, {
  String? hintText,
  String? errorText,
}) {
  final vcare = context.vcare;
  return InputDecoration(
    hintText: hintText,
    hintStyle: _FamilyFormTypography.hint(context),
    counterText: '',
    errorText: errorText,
    errorStyle: _FamilyFormTypography.error(context),
    filled: true,
    fillColor: vcare.card,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: vcare.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: vcare.border),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: VCareColors.destructive),
    ),
  );
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photoUrl,
    required this.name,
    required this.onChangePhoto,
    this.onRemovePhoto,
  });

  final String? photoUrl;
  final String name;
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: vcare.muted,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: ProfileAvatar(
                name: name,
                photoUrl: photoUrl,
                size: 96,
                circular: true,
                initialsFontSize: 20,
                emptyIconSize: 32,
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
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VCareColors.background,
                        width: 2,
                      ),
                    ),
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

class _FamilyField extends StatelessWidget {
  const _FamilyField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _FamilyFormTypography.label(context),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DropdownOption {
  const _DropdownOption(this.value, this.label);

  final String value;
  final String label;
}

class _FamilyDropdown extends StatelessWidget {
  const _FamilyDropdown({
    required this.value,
    required this.hint,
    this.stringItems = const [],
    this.options = const [],
    required this.onChanged,
    this.errorText,
  });

  final String value;
  final String hint;
  final List<String> stringItems;
  final List<_DropdownOption> options;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final dropdownItems = <DropdownMenuItem<String>>[
      for (final item in stringItems)
        DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: _FamilyFormTypography.select(context)),
        ),
      for (final item in options)
        DropdownMenuItem<String>(
          value: item.value,
          child: Text(
            item.label,
            style: _FamilyFormTypography.select(context),
          ),
        ),
    ];

    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      hint: Text(
        hint,
        style: _FamilyFormTypography.hint(context),
      ),
      style: _FamilyFormTypography.select(context),
      items: dropdownItems,
      onChanged: onChanged,
      isExpanded: true,
      decoration: _inputDecoration(context, errorText: errorText),
      borderRadius: BorderRadius.circular(16),
      icon: Icon(
        LucideIcons.chevronDown,
        size: 16,
        color: vcare.mutedForeground.withValues(alpha: 0.7),
      ),
    );
  }
}

abstract final class _FamilyFormTypography {
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

  static TextStyle error(BuildContext context) {
    return context.textTheme.regular12?.copyWith(
          color: VCareColors.destructive,
          height: 1.25,
        ) ??
        TextStyle(fontSize: 12, color: VCareColors.destructive);
  }
}
