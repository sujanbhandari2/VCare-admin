import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/utils/image_picker_utils.dart';
import 'package:vcare_admin/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:vcare_admin/shared/widgets/profile_avatar.dart';
import 'package:vcare_admin/shared/widgets/vcare_toast.dart';

/// Avatar editor for account profile — camera/gallery pick, optional remove.
class AccountPhotoEditor extends StatelessWidget {
  const AccountPhotoEditor({
    super.key,
    required this.name,
    required this.photoUrl,
    this.photoCacheKey,
    required this.enabled,
    required this.onPhotoChanged,
    this.onPhotoRemoved,
    this.canRemove = false,
  });

  final String name;
  final String? photoUrl;
  final String? photoCacheKey;
  final bool enabled;
  final ValueChanged<String> onPhotoChanged;
  final VoidCallback? onPhotoRemoved;
  final bool canRemove;

  Future<void> _pickPhoto(BuildContext context) async {
    if (!enabled) {
      return;
    }

    await ImagePickerSourceSelectionBottomSheet.show<void>(
      context,
      onGalleryPick: () => _handlePick(context, ImagePickerUtils.fromGallery),
      onCameraPick: () => _handlePick(context, ImagePickerUtils.fromCamera),
    );
  }

  Future<void> _handlePick(
    BuildContext context,
    Future<XFile?> Function() pick,
  ) async {
    final file = await pick();
    if (file == null || !context.mounted) {
      return;
    }

    final pickedFile = File(file.path);
    final bytes = await pickedFile.length();
    if (bytes > ProfileEditValidation.maxProfilePhotoBytes) {
      if (!context.mounted) {
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

    onPhotoChanged(pickedFile.path);
  }

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;
    final hasPhoto = (photoUrl?.trim().isNotEmpty ?? false);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 96,
              height: 96,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: vcare.border),
              ),
              child: ProfileAvatar(
                name: name,
                photoUrl: photoUrl,
                photoCacheKey: photoCacheKey,
                size: 96,
                circular: true,
                initialsFontSize: 28,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: enabled ? vcare.primary : vcare.muted,
                shape: const CircleBorder(),
                elevation: enabled ? 2 : 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: enabled ? () => _pickPhoto(context) : null,
                  child: Container(
                    width: 32,
                    height: 32,
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
                      color: enabled
                          ? context.theme.colorScheme.onPrimary
                          : vcare.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Profile photo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: vcare.foreground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasPhoto ? 'PNG, JPG, WEBP, or GIF up to 25 MB' : 'Tap the camera to upload',
          style: TextStyle(
            fontSize: 12,
            color: vcare.mutedForeground,
          ),
        ),
        if (canRemove && onPhotoRemoved != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: enabled ? onPhotoRemoved : null,
            style: TextButton.styleFrom(
              foregroundColor: vcare.mutedForeground,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Remove photo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

/// True when [photoUrl] points at a local file rather than a remote/asset URL.
bool isLocalAccountPhotoPath(String? photoUrl) {
  final path = photoUrl?.trim();
  if (path == null || path.isEmpty) {
    return false;
  }
  final lower = path.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return false;
  }
  if (lower.startsWith('assets/')) {
    return false;
  }
  return true;
}
