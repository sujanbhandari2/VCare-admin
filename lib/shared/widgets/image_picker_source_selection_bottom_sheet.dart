import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_floating_bottom_sheet.dart';

class ImagePickerSourceSelectionBottomSheet extends StatefulWidget {
  final VoidCallback? onGalleryPick;
  final VoidCallback? onCameraPick;
  final bool showDragLine;

  const ImagePickerSourceSelectionBottomSheet({
    super.key,
    this.onGalleryPick,
    this.onCameraPick,
    this.showDragLine = false,
  });

  /// Method to show bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    VoidCallback? onGalleryPick,
    VoidCallback? onCameraPick,
    EdgeInsetsGeometry? margin,
    bool showDragLine = false,
  }) {
    return context.showBottomSheet<T>(
      builder: (BuildContext context) {
        return ImagePickerSourceSelectionBottomSheet(
          onCameraPick: onCameraPick,
          onGalleryPick: onGalleryPick,
          showDragLine: showDragLine,
        );
      },
      enableDrag: false,
      margin: margin ?? vcareCompactBottomSheetMargin(context),
      topRadius: 12,
      showDragHandle: showDragLine,
    );
  }

  @override
  State<ImagePickerSourceSelectionBottomSheet> createState() =>
      _ImagePickerSourceSelectionBottomSheetState();
}

class _ImagePickerSourceSelectionBottomSheetState
    extends State<ImagePickerSourceSelectionBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: widget.showDragLine ? 0 : 8,
        bottom: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ui4Item(
            icon: Icons.camera_enhance_outlined,
            label: context.appLocalization.camera,
            onClick: widget.onCameraPick,
          ),
          _ui4Item(
            icon: Icons.image_outlined,
            label: context.appLocalization.gallery,
            onClick: widget.onGalleryPick,
          ),
        ],
      ),
    );
  }

  /// Ui for item
  Widget _ui4Item({
    required IconData? icon,
    required String label,
    VoidCallback? onClick,
  }) {
    return InkWell(
      onTap: () {
        context.pop();
        Future.delayed(const Duration(milliseconds: 225), onClick);
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 16.0),
            Flexible(child: Text(label, style: context.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
