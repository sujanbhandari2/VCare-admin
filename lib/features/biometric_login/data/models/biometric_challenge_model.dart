import 'package:vcare_admin/features/biometric_login/domain/entities/biometric_challenge.dart';

class BiometricChallengeModel {
  const BiometricChallengeModel({
    required this.challengeToken,
    required this.nonce,
  });

  final String challengeToken;
  final String nonce;

  factory BiometricChallengeModel.fromJson(Map<String, dynamic> json) {
    return BiometricChallengeModel(
      challengeToken: _extractString(
        json,
        const ['challengeToken', 'challenge_token', 'token'],
      ),
      nonce: _extractString(
        json,
        const ['nonce', 'challengeNonce', 'challenge_nonce'],
      ),
    );
  }

  BiometricChallenge toEntity() {
    return BiometricChallenge(
      challengeToken: challengeToken,
      nonce: nonce,
    );
  }

  static String _extractString(
    dynamic value,
    List<String> keys,
  ) {
    if (value is Map<String, dynamic>) {
      for (final key in keys) {
        final directValue = value[key];
        final resolved = _normalizeString(directValue);
        if (resolved != null) {
          return resolved;
        }
      }

      for (final entry in value.entries) {
        final resolved = _extractString(entry.value, keys);
        if (resolved.isNotEmpty) {
          return resolved;
        }
      }
    } else if (value is Iterable) {
      for (final item in value) {
        final resolved = _extractString(item, keys);
        if (resolved.isNotEmpty) {
          return resolved;
        }
      }
    }

    return '';
  }

  static String? _normalizeString(dynamic value) {
    if (value == null) {
      return null;
    }
    final resolved = value is String ? value.trim() : value.toString().trim();
    return resolved.isEmpty ? null : resolved;
  }
}
