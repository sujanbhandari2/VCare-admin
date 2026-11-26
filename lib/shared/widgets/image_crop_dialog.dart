import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vcare_admin/core/styles/vcare_colors.dart';
import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/shared/utils/image_cropper.dart';
import 'package:vcare_admin/shared/widgets/app_button.dart';

/// In-app crop dialog for profile photos and document attachments.
///
/// When [aspectRatio] is null, selection is free-aspect. When set (e.g. `1.0`
/// for a square profile photo), resize keeps that ratio. Returns cropped JPEG
/// bytes, or null when cancelled.
class ImageCropDialog extends StatefulWidget {
  const ImageCropDialog({
    super.key,
    required this.bytes,
    this.title = 'Crop image',
    this.aspectRatio,
  });

  final Uint8List bytes;
  final String title;

  /// Width / height. Null = free crop; `1.0` = square.
  final double? aspectRatio;

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List bytes,
    String title = 'Crop image',
    double? aspectRatio,
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) =>
          ImageCropDialog(bytes: bytes, title: title, aspectRatio: aspectRatio),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  ui.Image? _image;
  Rect? _cropRect;
  Rect _imageRect = Rect.zero;
  ImageCropHandle? _activeHandle;
  int? _activePointer;
  bool _processing = false;
  bool _failed = false;
  bool _layoutScheduled = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final image = await decodeImageFromList(widget.bytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _scheduleImageLayout(Size stageSize, ui.Image image) {
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(image.width.toDouble(), image.height.toDouble()),
      stageSize,
    );
    final destination = fitted.destination;
    final nextImageRect = Rect.fromLTWH(
      (stageSize.width - destination.width) / 2,
      (stageSize.height - destination.height) / 2,
      destination.width,
      destination.height,
    );

    if (_imageRect == nextImageRect && _cropRect != null) return;
    if (_layoutScheduled) return;

    _layoutScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _layoutScheduled = false;
      if (!mounted) return;
      setState(() {
        final previous = _imageRect;
        _imageRect = nextImageRect;
        if (_cropRect == null || previous == Rect.zero) {
          _cropRect = initialCropRectForAspect(
            bounds: nextImageRect,
            aspectRatio: widget.aspectRatio,
          );
        } else {
          _cropRect = clampCropRectToBounds(_cropRect!, nextImageRect);
        }
      });
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_processing) return;
    final crop = _cropRect;
    if (crop == null || crop.isEmpty) return;

    final handle = _hitTest(event.localPosition, crop);
    if (handle == null) return;

    _activePointer = event.pointer;
    _activeHandle = handle;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_processing || event.pointer != _activePointer) return;
    final handle = _activeHandle;
    final crop = _cropRect;
    if (handle == null || crop == null || crop.isEmpty) return;

    final next = _applyDrag(
      rect: crop,
      handle: handle,
      delta: event.delta,
      bounds: _imageRect,
    );
    if (next == crop) return;
    setState(() => _cropRect = next);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _activeHandle = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _activeHandle = null;
  }

  ImageCropHandle? _hitTest(Offset point, Rect rect) {
    // Larger hit area so edge/corner grabbers feel responsive on phones.
    const tolerance = 36.0;
    final withinX =
        point.dx >= rect.left - tolerance && point.dx <= rect.right + tolerance;
    final withinY =
        point.dy >= rect.top - tolerance && point.dy <= rect.bottom + tolerance;
    if (!withinX || !withinY) return null;

    final nearLeft = (point.dx - rect.left).abs() <= tolerance;
    final nearRight = (point.dx - rect.right).abs() <= tolerance;
    final nearTop = (point.dy - rect.top).abs() <= tolerance;
    final nearBottom = (point.dy - rect.bottom).abs() <= tolerance;

    if (nearLeft && nearTop) return ImageCropHandle.topLeft;
    if (nearRight && nearTop) return ImageCropHandle.topRight;
    if (nearLeft && nearBottom) return ImageCropHandle.bottomLeft;
    if (nearRight && nearBottom) return ImageCropHandle.bottomRight;
    if (nearLeft) return ImageCropHandle.left;
    if (nearRight) return ImageCropHandle.right;
    if (nearTop) return ImageCropHandle.top;
    if (nearBottom) return ImageCropHandle.bottom;
    if (rect.contains(point)) return ImageCropHandle.move;
    return null;
  }

  Rect _applyDrag({
    required Rect rect,
    required ImageCropHandle handle,
    required Offset delta,
    required Rect bounds,
  }) {
    if (bounds.isEmpty) return rect;

    if (handle == ImageCropHandle.move) {
      final moved = rect.shift(delta);
      var dx = 0.0;
      var dy = 0.0;
      if (moved.left < bounds.left) dx = bounds.left - moved.left;
      if (moved.right > bounds.right) dx = bounds.right - moved.right;
      if (moved.top < bounds.top) dy = bounds.top - moved.top;
      if (moved.bottom > bounds.bottom) dy = bounds.bottom - moved.bottom;
      return moved.shift(Offset(dx, dy));
    }

    const movesLeft = {
      ImageCropHandle.left,
      ImageCropHandle.topLeft,
      ImageCropHandle.bottomLeft,
    };
    const movesRight = {
      ImageCropHandle.right,
      ImageCropHandle.topRight,
      ImageCropHandle.bottomRight,
    };
    const movesTop = {
      ImageCropHandle.top,
      ImageCropHandle.topLeft,
      ImageCropHandle.topRight,
    };
    const movesBottom = {
      ImageCropHandle.bottom,
      ImageCropHandle.bottomLeft,
      ImageCropHandle.bottomRight,
    };

    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;

    if (movesLeft.contains(handle)) {
      left = (left + delta.dx).clamp(bounds.left, right - imageCropMinSide);
    }
    if (movesRight.contains(handle)) {
      right = (right + delta.dx).clamp(left + imageCropMinSide, bounds.right);
    }
    if (movesTop.contains(handle)) {
      top = (top + delta.dy).clamp(bounds.top, bottom - imageCropMinSide);
    }
    if (movesBottom.contains(handle)) {
      bottom = (bottom + delta.dy).clamp(top + imageCropMinSide, bounds.bottom);
    }

    var next = Rect.fromLTRB(left, top, right, bottom);
    final aspect = widget.aspectRatio;
    if (aspect != null && aspect > 0) {
      next = constrainCropRectToAspect(
        rect: next,
        bounds: bounds,
        aspectRatio: aspect,
        handle: handle,
      );
    }
    return next;
  }

  Future<void> _confirm() async {
    final image = _image;
    if (image == null || _processing) return;

    final cropRect = _cropRect ?? _imageRect;
    if (cropRect.isEmpty || _imageRect.isEmpty) return;

    setState(() => _processing = true);

    final result = await compute(
      runImageCrop,
      ImageCropJob(
        bytes: widget.bytes,
        cropInPixels: cropRectToImagePixels(
          cropRect: cropRect,
          imageRect: _imageRect,
          imageWidth: image.width,
          imageHeight: image.height,
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      setState(() {
        _processing = false;
        _failed = true;
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vcare = context.vcare;
    final media = MediaQuery.sizeOf(context);
    final stageHeight = (media.height * 0.55).clamp(280.0, 520.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VCareColors.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: media.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, vcare),
            Divider(height: 1, color: vcare.border),
            SizedBox(
              height: stageHeight,
              child: Container(
                color: vcare.muted,
                padding: const EdgeInsets.all(8),
                child: _buildStage(vcare),
              ),
            ),
            Divider(height: 1, color: vcare.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _failed
                        ? 'Could not process this image. Try another one.'
                        : 'Drag inside to reposition, or pull the corners and edges to resize freely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: _failed
                          ? VCareColors.destructive
                          : vcare.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.outlined(
                          text: 'Cancel',
                          height: 44,
                          padding: EdgeInsets.zero,
                          onPressed: _processing
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton.elevated(
                          text: 'Use photo',
                          height: 44,
                          padding: EdgeInsets.zero,
                          loading: _processing,
                          onPressed: _image == null || _processing
                              ? null
                              : _confirm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VCareThemeExtension vcare) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: VCareColors.foreground,
              ),
            ),
          ),
          IconButton(
            onPressed: _processing ? null : () => Navigator.of(context).pop(),
            icon: Icon(LucideIcons.x, size: 18, color: vcare.mutedForeground),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }

  Widget _buildStage(VCareThemeExtension vcare) {
    final image = _image;
    if (image == null) {
      return Center(
        child: _failed
            ? Icon(LucideIcons.imageOff, color: vcare.mutedForeground)
            : SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VCareColors.primary,
                ),
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stageSize = Size(constraints.maxWidth, constraints.maxHeight);
        _scheduleImageLayout(stageSize, image);

        final cropRect = _cropRect;
        if (_imageRect.isEmpty || cropRect == null) {
          return const SizedBox.expand();
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fromRect(
                rect: _imageRect,
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
              CustomPaint(
                painter: _CropOverlayPainter(
                  cropRect: cropRect,
                  accent: VCareColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.cropRect, required this.accent});

  final Rect cropRect;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.45);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(cropRect),
      ),
      dim,
    );

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = cropRect.left + cropRect.width * i / 3;
      final dy = cropRect.top + cropRect.height * i / 3;
      canvas.drawLine(
        Offset(dx, cropRect.top),
        Offset(dx, cropRect.bottom),
        grid,
      );
      canvas.drawLine(
        Offset(cropRect.left, dy),
        Offset(cropRect.right, dy),
        grid,
      );
    }

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(cropRect, border);

    final grabber = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    const armLength = 24.0;
    const thickness = 5.0;

    void bar(double left, double top, double width, double height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          const Radius.circular(2),
        ),
        grabber,
      );
    }

    // Corner brackets.
    bar(cropRect.left, cropRect.top, armLength, thickness);
    bar(cropRect.left, cropRect.top, thickness, armLength);
    bar(cropRect.right - armLength, cropRect.top, armLength, thickness);
    bar(cropRect.right - thickness, cropRect.top, thickness, armLength);
    bar(cropRect.left, cropRect.bottom - thickness, armLength, thickness);
    bar(cropRect.left, cropRect.bottom - armLength, thickness, armLength);
    bar(
      cropRect.right - armLength,
      cropRect.bottom - thickness,
      armLength,
      thickness,
    );
    bar(
      cropRect.right - thickness,
      cropRect.bottom - armLength,
      thickness,
      armLength,
    );

    // Mid-edge grabbers.
    const edgeLength = 32.0;
    bar(
      cropRect.center.dx - edgeLength / 2,
      cropRect.top,
      edgeLength,
      thickness,
    );
    bar(
      cropRect.center.dx - edgeLength / 2,
      cropRect.bottom - thickness,
      edgeLength,
      thickness,
    );
    bar(
      cropRect.left,
      cropRect.center.dy - edgeLength / 2,
      thickness,
      edgeLength,
    );
    bar(
      cropRect.right - thickness,
      cropRect.center.dy - edgeLength / 2,
      thickness,
      edgeLength,
    );
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.accent != accent;
}
