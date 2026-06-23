import 'package:vcare_admin/features/auth/presentation/state/login_flow_state.dart';

/// Normalizes login identifiers before API calls.
class AuthIdentifierNormalizer {
  AuthIdentifierNormalizer._();

  static String normalize({
    required LoginFlowMethod method,
    required String raw,
  }) {
    final trimmed = raw.trim();
    if (method == LoginFlowMethod.phone) {
      return trimmed.replaceAll(RegExp(r'\D'), '');
    }
    return trimmed.toLowerCase();
  }
}
