import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/core/styles/vcare_hsl.dart';

void main() {
  group('VCareHsl', () {
    test('parses valid hex into HSL parts', () {
      final hsl = VCareHsl.fromHex('#e06629');
      expect(hsl, isNotNull);
      // #e06629 ≈ hsl(21, 75%, 52%)
      expect(hsl!.h, closeTo(21, 3));
      expect(hsl.s, closeTo(75, 5));
      expect(hsl.l, closeTo(52, 3));
    });

    test('rejects invalid hex', () {
      expect(VCareHsl.fromHex('not-a-color'), isNull);
      expect(VCareHsl.fromHex('#fff'), isNull);
    });

    test('normalizeHex lowercases and keeps fallback', () {
      expect(VCareHsl.normalizeHex('#E06629'), '#e06629');
      expect(VCareHsl.normalizeHex('bad'), '#e06629');
    });
  });

  group('VCareColorScale.fromHex', () {
    test('generates 50-800 steps matching web lightness targets', () {
      final scale = VCareColorScale.fromHex('#e06629');
      final hsl50 = HSLColor.fromColor(scale.s50);
      final hsl800 = HSLColor.fromColor(scale.s800);
      final hsl500 = HSLColor.fromColor(scale.s500);

      expect(hsl50.lightness, closeTo(0.97, 0.02));
      expect(hsl800.lightness, closeTo(0.24, 0.02));
      // Step 500 uses the input color's lightness.
      expect(hsl500.lightness, closeTo(0.52, 0.05));
    });

    test('primary and secondary defaults are distinct', () {
      expect(
        VCareColorScale.primaryDefault.s500.toARGB32(),
        isNot(VCareColorScale.secondaryDefault.s500.toARGB32()),
      );
    });
  });
}
