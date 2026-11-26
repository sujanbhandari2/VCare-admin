import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/shared/utils/image_cropper.dart';

void main() {
  group('cropRectToImagePixels', () {
    test('scales the selection from preview space to source pixels', () {
      final pixels = cropRectToImagePixels(
        cropRect: const Rect.fromLTWH(60, 40, 100, 50),
        imageRect: const Rect.fromLTWH(10, 20, 200, 100),
        imageWidth: 800,
        imageHeight: 400,
      );

      expect(pixels.left, 200);
      expect(pixels.top, 80);
      expect(pixels.width, 400);
      expect(pixels.height, 200);
    });

    test('clamps a selection that overflows the preview', () {
      final pixels = cropRectToImagePixels(
        cropRect: const Rect.fromLTWH(-50, -50, 400, 400),
        imageRect: const Rect.fromLTWH(0, 0, 200, 100),
        imageWidth: 400,
        imageHeight: 200,
      );

      expect(pixels, const Rect.fromLTRB(0, 0, 400, 200));
    });

    test('falls back to the full image when the preview has no size', () {
      final pixels = cropRectToImagePixels(
        cropRect: const Rect.fromLTWH(0, 0, 10, 10),
        imageRect: Rect.zero,
        imageWidth: 120,
        imageHeight: 90,
      );

      expect(pixels, const Rect.fromLTWH(0, 0, 120, 90));
    });
  });

  group('imageCropOutputSize', () {
    test('keeps dimensions under the cap unchanged', () {
      expect(imageCropOutputSize(1200, 800), const Size(1200, 800));
    });

    test('caps the long side and preserves the aspect ratio', () {
      expect(imageCropOutputSize(3200, 1600), const Size(1600, 800));
      expect(imageCropOutputSize(800, 3200), const Size(400, 1600));
    });
  });

  group('initialCropRectForAspect', () {
    test('returns bounds when aspect is null', () {
      const bounds = Rect.fromLTWH(10, 20, 200, 100);
      expect(
        initialCropRectForAspect(bounds: bounds, aspectRatio: null),
        bounds,
      );
    });

    test('builds a centered square inside landscape bounds', () {
      const bounds = Rect.fromLTWH(0, 0, 200, 100);
      final rect = initialCropRectForAspect(bounds: bounds, aspectRatio: 1);

      expect(rect.width, 100);
      expect(rect.height, 100);
      expect(rect.left, 50);
      expect(rect.top, 0);
    });
  });

  group('clampCropRectToBounds', () {
    test('shifts an overflowing rect back inside bounds', () {
      const bounds = Rect.fromLTWH(0, 0, 200, 100);
      final clamped = clampCropRectToBounds(
        const Rect.fromLTWH(180, -10, 80, 60),
        bounds,
      );

      expect(clamped.left, 120);
      expect(clamped.top, 0);
      expect(clamped.width, 80);
      expect(clamped.height, 60);
    });
  });
}
