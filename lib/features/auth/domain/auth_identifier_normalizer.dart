import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';

/// Normalizes login identifiers before API calls.
class AuthIdentifierNormalizer {
  AuthIdentifierNormalizer._();

  static String normalize({
    required LoginFlowMethod method,
    required String raw,
    AuthPhoneCountry? phoneCountry,
  }) {
    final trimmed = raw.trim();
    if (method == LoginFlowMethod.phone) {
      final national = trimmed.replaceAll(RegExp(r'\D'), '');
      if (phoneCountry != null) {
        return AuthPhoneFormatter.toApiDigits(phoneCountry.dialCode, national);
      }
      return national;
    }
    return trimmed.toLowerCase();
  }
}
