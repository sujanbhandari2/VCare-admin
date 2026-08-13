abstract final class TenantBrandingValidators {
  static final _hexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');
  static final _httpUrl = RegExp(r'^https?:\/\/', caseSensitive: false);
  static final _dataUrl = RegExp(r'^data:image\/[a-zA-Z0-9.+-]+;base64,');

  static bool isHexColor(String? value) {
    if (value == null) return false;
    return _hexColor.hasMatch(value.trim());
  }

  static String? validateHexColor(String? value, {String field = 'Color'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    if (!isHexColor(value)) {
      return '$field must be a 6-digit hex color (e.g. #e06629)';
    }
    return null;
  }

  static bool isValidImageSource(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    final text = value.trim();
    return _httpUrl.hasMatch(text) || _dataUrl.hasMatch(text);
  }

  static String? validateImageSource(String? value, {String field = 'Image'}) {
    if (!isValidImageSource(value)) {
      return '$field must be a URL or image data URL';
    }
    return null;
  }
}
