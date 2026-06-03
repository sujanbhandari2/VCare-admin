import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageColorExtractor {
  ImageColorExtractor._();

  static Future<Color?> extractDominantColor(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final imageProvider = MemoryImage(bytes);
      final scheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        dynamicSchemeVariant: DynamicSchemeVariant.content,
      );

      return scheme.primary;
    } catch (_) {
      return null;
    }
  }
}
