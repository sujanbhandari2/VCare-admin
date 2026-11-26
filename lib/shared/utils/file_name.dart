/// Split `report.pdf` → base `report`, extension `.pdf`.
({String baseName, String extension}) splitFileName(String filename) {
  final trimmed = filename.trim();
  final lastDot = trimmed.lastIndexOf('.');
  if (lastDot <= 0 || lastDot == trimmed.length - 1) {
    return (baseName: trimmed, extension: '');
  }
  return (
    baseName: trimmed.substring(0, lastDot),
    extension: trimmed.substring(lastDot),
  );
}

/// Join base + extension. Returns empty string when base is blank.
String joinFileName(String baseName, String extension) {
  final base = baseName.trim();
  if (base.isEmpty) return '';
  return '$base$extension';
}

/// Strip characters illegal in file names: `\ / : * ? " < > |`
String sanitizeFileBaseName(String value) {
  return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
}

/// Whether [mime] should go through the image crop step.
bool shouldCropUploadMime(String? mime) {
  final trimmed = mime?.trim().toLowerCase() ?? '';
  return trimmed.startsWith('image/');
}

/// Force a `.jpg` display name after image crop (client case parity).
String defaultDisplayNameForImage(String originalName) {
  final trimmed = originalName.trim();
  final base = trimmed.isEmpty ? 'photo' : trimmed;
  return '${base.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg';
}
