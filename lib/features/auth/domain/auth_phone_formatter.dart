import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';

/// Formats normalized phone digits for API requests.
class AuthPhoneFormatter {
  AuthPhoneFormatter._();

  /// Combines dial code and national digits for API payloads (no `+` prefix).
  static String toApiDigits(String dialCode, String nationalDigits) {
    final national = nationalDigits.replaceAll(RegExp(r'\D'), '');
    if (national.isEmpty) return '';
    return '$dialCode$national';
  }

  /// Strips country code for display in phone input fields.
  static String toDisplayDigits(
    String phone, {
    AuthPhoneCountry fallback = AuthPhoneCountry.usa,
  }) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('977') && digits.length > 3) {
      return digits.substring(3);
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return digits.substring(1);
    }
    if (digits.length == 10) return digits;
    return digits;
  }

  /// Formats national digits for display in phone input fields.
  static String formatNationalDisplay(
    String input,
    AuthPhoneCountry country,
  ) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return '';
    }

    return switch (country) {
      AuthPhoneCountry.usa || AuthPhoneCountry.canada =>
        _formatNorthAmerica(digits),
      AuthPhoneCountry.nepal => _formatNepal(digits),
    };
  }

  static String _formatNorthAmerica(String digits) {
    if (digits.length <= 3) {
      return '($digits';
    }
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    return '(${digits.substring(0, 3)}) '
        '${digits.substring(3, 6)}-${digits.substring(6)}';
  }

  static String _formatNepal(String digits) {
    if (digits.length <= 3) {
      return digits;
    }
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 7)} '
        '${digits.substring(7)}';
  }

  /// Infers country from API-style digits when pre-filling phone fields.
  static AuthPhoneCountry detectCountry(
    String phone, {
    AuthPhoneCountry fallback = AuthPhoneCountry.usa,
  }) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return fallback;

    if (digits.startsWith('977') && digits.length > 10) {
      return AuthPhoneCountry.nepal;
    }
    if (digits.length == 11 && digits.startsWith('1')) {
      return AuthPhoneCountry.usa;
    }
    return fallback;
  }

  /// Formats a stored phone value for display with country code, e.g. +1 (555) 123-4567.
  static String formatInternationalDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    final country = detectCountry(phone);
    final national = toDisplayDigits(phone, fallback: country);
    if (national.isEmpty) return '';

    final formattedNational = formatNationalDisplay(national, country);
    return '${country.dialCodeDisplay} $formattedNational';
  }

  @Deprecated('Use toApiDigits for API payloads without + prefix')
  static String toE164(String digitsOnly) {
    final digits = digitsOnly.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return '+$digits';
  }
}
