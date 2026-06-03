import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_template/shared/utils/dash_painter.dart';
import 'package:flutter_template/shared/utils/image_picker_utils.dart';
import 'package:flutter_template/shared/widgets/image_picker_source_selection_bottom_sheet.dart';
import 'package:flutter_template/core/styles/app_colors.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    this.selected,
    this.margin = .zero,
    this.radius = .zero,
    this.onSelected,
    this.enabled = true,
    this.required = false,
  });

  final String label;
  final XFile? selected;
  final EdgeInsetsGeometry margin;
  final Radius radius;
  final void Function(XFile?)? onSelected;
  final bool enabled;
  final bool required;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  /// Picked Image
  ///
  XFile? _image;

  /// Init State
  ///
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _image = widget.selected;
      });
    });
  }

  /// Method to handle image picker
  void _handleImagePicked() {
    ImagePickerSourceSelectionBottomSheet.show(
      context,
      onGalleryPick: () async {
        final image = await ImagePickerUtils.fromGallery();

        if (mounted && image != null) {
          setState(() {
            _image = image;
          });

          widget.onSelected?.call(image);
        }
      },
      onCameraPick: () async {
        final image = await ImagePickerUtils.fromCamera();

        if (mounted && image != null) {
          setState(() {
            _image = image;
          });

          widget.onSelected?.call(image);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          if (widget.required)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.label,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: !widget.enabled ? context.theme.hintColor : null,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '*',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: !widget.enabled
                          ? context.theme.hintColor
                          : context.theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              widget.label,
              style: context.textTheme.bodySmall?.copyWith(
                color: !widget.enabled ? context.theme.hintColor : null,
              ),
            ),
          const SizedBox(height: 8.0),
          Stack(
            children: [
              GestureDetector(
                onTap: widget.enabled ? _handleImagePicked : null,
                child: CustomPaint(
                  painter: DashPainter(
                    radius: widget.radius,
                    dashPattern: [4.0],
                  ),
                  child: SizedBox(
                    height: 150.0,
                    width: double.maxFinite,
                    child: _image != null
                        ? Container(
                            margin: const .all(8.0),
                            decoration: BoxDecoration(
                              borderRadius: .circular(8.0),
                            ),
                            clipBehavior: .antiAlias,
                            child: Image.file(File(_image!.path)),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: .min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: context.theme.primaryColor,
                                  size: 32.0,
                                ),
                                Text(
                                  context.appLocalization.upload_photo,
                                  style: context.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              if (_image != null)
                Positioned(
                  right: 0,
                  child: Padding(
                    padding: const .only(top: 4.0, right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          //removes the selected image
                          _image = null;
                        });
                      },
                      child: const Icon(Icons.close, color: AppColors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
