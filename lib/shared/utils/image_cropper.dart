import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:image/image.dart' as img;

/// Default max long-side dimension after crop (vcareapp Request New `maxOutput: 1600`).
const imageCropDefaultMaxOutput = 1600;

/// Default JPEG quality 0–100 (web default `quality: 0.9`).
const imageCropDefaultQuality = 90;

/// Smallest crop selection allowed on screen, in logical pixels.
const imageCropMinSide = 56.0;

/// Max long-side for request-new attachments — alias of [imageCropDefaultMaxOutput].
const requestNewImageCropMaxOutput = imageCropDefaultMaxOutput;

/// JPEG quality for request-new — alias of [imageCropDefaultQuality].
const requestNewImageCropQuality = imageCropDefaultQuality;

/// Alias of [imageCropMinSide] for cases call sites.
const requestCropMinSide = imageCropMinSide;

/// Maps a crop selection drawn over the previewed image into source pixels.
///
/// [cropRect] and [imageRect] share the same widget coordinate space;
/// [imageRect] is where the image is actually painted after `BoxFit.contain`.
Rect cropRectToImagePixels({
  required Rect cropRect,
  required Rect imageRect,
  required int imageWidth,
  required int imageHeight,
}) {
  if (imageRect.width <= 0 || imageRect.height <= 0) {
    return Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble());
  }

  final scaleX = imageWidth / imageRect.width;
  final scaleY = imageHeight / imageRect.height;

  final left = ((cropRect.left - imageRect.left) * scaleX).clamp(
    0.0,
    imageWidth.toDouble(),
  );
  final top = ((cropRect.top - imageRect.top) * scaleY).clamp(
    0.0,
    imageHeight.toDouble(),
  );
  final right = ((cropRect.right - imageRect.left) * scaleX).clamp(
    0.0,
    imageWidth.toDouble(),
  );
  final bottom = ((cropRect.bottom - imageRect.top) * scaleY).clamp(
    0.0,
    imageHeight.toDouble(),
  );

  return Rect.fromLTRB(left, top, right, bottom);
}

/// Alias of [cropRectToImagePixels] for cases call sites.
Rect requestCropRectToImagePixels({
  required Rect cropRect,
  required Rect imageRect,
  required int imageWidth,
  required int imageHeight,
}) {
  return cropRectToImagePixels(
    cropRect: cropRect,
    imageRect: imageRect,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
  );
}

/// Output size after capping the long side at [maxDimension].
Size imageCropOutputSize(
  int width,
  int height, {
  int maxDimension = imageCropDefaultMaxOutput,
}) {
  final longSide = width > height ? width : height;
  if (longSide <= maxDimension || longSide == 0) {
    return Size(width.toDouble(), height.toDouble());
  }

  final scale = maxDimension / longSide;
  final scaledWidth = (width * scale).round().clamp(1, maxDimension);
  final scaledHeight = (height * scale).round().clamp(1, maxDimension);
  return Size(scaledWidth.toDouble(), scaledHeight.toDouble());
}

/// Alias of [imageCropOutputSize] for cases call sites.
Size requestCropOutputSize(
  int width,
  int height, {
  int maxDimension = requestNewImageCropMaxOutput,
}) {
  return imageCropOutputSize(width, height, maxDimension: maxDimension);
}

/// Builds the largest centered rectangle inside [bounds] with [aspectRatio].
///
/// When [aspectRatio] is null, returns [bounds] unchanged.
Rect initialCropRectForAspect({required Rect bounds, double? aspectRatio}) {
  if (aspectRatio == null || aspectRatio <= 0 || bounds.isEmpty) {
    return bounds;
  }

  final boundsAspect = bounds.width / bounds.height;
  if (boundsAspect > aspectRatio) {
    final width = bounds.height * aspectRatio;
    final left = bounds.left + (bounds.width - width) / 2;
    return Rect.fromLTWH(left, bounds.top, width, bounds.height);
  }

  final height = bounds.width / aspectRatio;
  final top = bounds.top + (bounds.height - height) / 2;
  return Rect.fromLTWH(bounds.left, top, bounds.width, height);
}

/// Keeps [rect] inside [bounds] while preserving size when possible.
Rect clampCropRectToBounds(Rect rect, Rect bounds) {
  if (bounds.isEmpty) return rect;
  if (rect.isEmpty) return bounds;

  final width = rect.width.clamp(imageCropMinSide, bounds.width);
  final height = rect.height.clamp(imageCropMinSide, bounds.height);

  final left = rect.left.clamp(bounds.left, bounds.right - width);
  final top = rect.top.clamp(bounds.top, bounds.bottom - height);

  return Rect.fromLTWH(left, top, width, height);
}

/// Constrains [rect] to [aspectRatio] while staying inside [bounds].
Rect constrainCropRectToAspect({
  required Rect rect,
  required Rect bounds,
  required double aspectRatio,
  required ImageCropHandle handle,
}) {
  var left = rect.left;
  var top = rect.top;
  var right = rect.right;
  var bottom = rect.bottom;
  var width = right - left;
  var height = bottom - top;

  final fromCorner =
      handle == ImageCropHandle.topLeft ||
      handle == ImageCropHandle.topRight ||
      handle == ImageCropHandle.bottomLeft ||
      handle == ImageCropHandle.bottomRight;

  if (fromCorner ||
      handle == ImageCropHandle.left ||
      handle == ImageCropHandle.right) {
    height = width / aspectRatio;
    if (handle == ImageCropHandle.topLeft ||
        handle == ImageCropHandle.topRight ||
        handle == ImageCropHandle.top) {
      top = bottom - height;
    } else {
      bottom = top + height;
    }
  } else {
    width = height * aspectRatio;
    if (handle == ImageCropHandle.topLeft ||
        handle == ImageCropHandle.bottomLeft ||
        handle == ImageCropHandle.left) {
      left = right - width;
    } else {
      right = left + width;
    }
  }

  var next = Rect.fromLTRB(left, top, right, bottom);

  // Scale down if we overflow bounds while preserving aspect.
  if (next.width > bounds.width || next.height > bounds.height) {
    next = initialCropRectForAspect(bounds: bounds, aspectRatio: aspectRatio);
  } else {
    var dx = 0.0;
    var dy = 0.0;
    if (next.left < bounds.left) dx = bounds.left - next.left;
    if (next.right > bounds.right) dx = bounds.right - next.right;
    if (next.top < bounds.top) dy = bounds.top - next.top;
    if (next.bottom > bounds.bottom) dy = bounds.bottom - next.bottom;
    next = next.shift(Offset(dx, dy));
  }

  return next;
}

/// Which part of the crop selection a drag is currently manipulating.
enum ImageCropHandle {
  move,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

/// Alias of [ImageCropHandle] for cases call sites.
typedef RequestCropHandle = ImageCropHandle;

/// Isolate payload for [runImageCrop].
class ImageCropJob {
  const ImageCropJob({
    required this.bytes,
    required this.cropInPixels,
    this.maxOutput = imageCropDefaultMaxOutput,
    this.quality = imageCropDefaultQuality,
  });

  final Uint8List bytes;
  final Rect cropInPixels;
  final int maxOutput;
  final int quality;
}

/// Alias of [ImageCropJob] for cases call sites.
typedef RequestImageCropJob = ImageCropJob;

/// Decodes, crops and re-encodes as JPEG. Safe to run through `compute`.
Uint8List? runImageCrop(ImageCropJob job) {
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) return null;

  // Flutter's preview applies EXIF orientation, so bake it before cropping to
  // keep the selection aligned with what the user saw.
  final source = img.bakeOrientation(decoded);

  final x = job.cropInPixels.left.round().clamp(0, source.width - 1);
  final y = job.cropInPixels.top.round().clamp(0, source.height - 1);
  final width = job.cropInPixels.width.round().clamp(1, source.width - x);
  final height = job.cropInPixels.height.round().clamp(1, source.height - y);

  var cropped = img.copyCrop(source, x: x, y: y, width: width, height: height);

  final output = imageCropOutputSize(
    cropped.width,
    cropped.height,
    maxDimension: job.maxOutput,
  );
  if (output.width != cropped.width || output.height != cropped.height) {
    cropped = img.copyResize(
      cropped,
      width: output.width.round(),
      height: output.height.round(),
      interpolation: img.Interpolation.average,
    );
  }

  return img.encodeJpg(cropped, quality: job.quality);
}

/// Alias of [runImageCrop] for cases call sites.
Uint8List? runRequestImageCrop(RequestImageCropJob job) => runImageCrop(job);
