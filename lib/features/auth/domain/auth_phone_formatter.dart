/// Formats normalized phone digits for API requests.
class AuthPhoneFormatter {
  AuthPhoneFormatter._();

  static String toE164(String digitsOnly) {
    final digits = digitsOnly.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 10) return '+1$digits';
    if (digits.length == 11 && digits.startsWith('1')) return '+$digits';
    return '+$digits';
  }

  /// Strips country code for 10-digit display in onboard phone field.
  static String toDisplayDigits(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 11 && digits.startsWith('1')) {
      return digits.substring(1);
    }
    if (digits.length == 10) return digits;
    return digits;
  }
}
