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

  @Deprecated('Use toApiDigits for API payloads without + prefix')
  static String toE164(String digitsOnly) {
    final digits = digitsOnly.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return '+$digits';
  }
}
