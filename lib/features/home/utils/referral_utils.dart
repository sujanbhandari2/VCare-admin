// Referral link, QR, and agent-code helpers.
// parity: vcare-agent-app-2.0/src/features/id-card/components/VCareReferralCard.tsx
// parity: vcare-agent-app-2.0/src/features/home/api/agent-code.schemas.ts

/// 3–64 chars; letters, numbers, hyphens only (stored lowercase).
final agentCodePattern = RegExp(r'^[a-zA-Z0-9-]{3,64}$');

const referralUrlPrefix = 'vcare.app/refer/';

class ReferralUrlParts {
  const ReferralUrlParts({
    required this.prefix,
    required this.code,
  });

  final String prefix;
  final String code;
}

String referralUsernameFromEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email.toLowerCase();
  return email.substring(0, at).toLowerCase();
}

/// Strips whitespace, trims, and lowercases for API submission.
String normalizeAgentCode(String raw) {
  return raw.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase();
}

String? validateAgentCode(String value) {
  final trimmed = value.trim();
  if (trimmed.length < 3) return 'Code must be at least 3 characters';
  if (trimmed.length > 64) return 'Code must be at most 64 characters';
  if (!agentCodePattern.hasMatch(trimmed)) {
    return 'Use only letters, numbers, and hyphens';
  }
  return null;
}

String referralUrlFromSlug(String slug) => 'https://$referralUrlPrefix$slug';

String referralUrlFromEmail(String email) =>
    referralUrlFromSlug(referralUsernameFromEmail(email));

/// Uses the server-provided [referralLink] when available, otherwise derives
/// a link from the user's email slug.
String resolveReferralUrl({
  required String email,
  String? referralLink,
}) {
  final trimmedLink = referralLink?.trim();
  if (trimmedLink != null && trimmedLink.isNotEmpty) {
    return trimmedLink;
  }
  return referralUrlFromEmail(email);
}

/// Splits a referral URL into a read-only prefix and editable code segment.
/// Prefer [agentCode] when provided; otherwise use the last path segment.
ReferralUrlParts splitReferralUrl(
  String referralUrl, {
  String? agentCode,
}) {
  final fallbackCode = agentCode?.trim() ?? '';
  try {
    final url = Uri.parse(referralUrl);
    if (!url.hasScheme || url.host.isEmpty) {
      return ReferralUrlParts(
        prefix: '',
        code: fallbackCode.isNotEmpty ? fallbackCode : referralUrl,
      );
    }

    final parts = url.pathSegments.where((s) => s.isNotEmpty).toList();
    final last = parts.isNotEmpty ? Uri.decodeComponent(parts.last) : '';
    final code = fallbackCode.isNotEmpty ? fallbackCode : last;
    final basePath = parts.length > 1 ? parts.sublist(0, parts.length - 1).join('/') : '';
    final prefix =
        '${url.origin}/${basePath.isNotEmpty ? '$basePath/' : ''}';
    return ReferralUrlParts(prefix: prefix, code: code);
  } catch (_) {
    return ReferralUrlParts(
      prefix: '',
      code: fallbackCode.isNotEmpty ? fallbackCode : referralUrl,
    );
  }
}

/// Rewrites the last path segment of [referralLink] to [agentCode].
String? replaceReferralCode(String? referralLink, String agentCode) {
  final trimmed = referralLink?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  try {
    final url = Uri.parse(trimmed);
    if (!url.hasScheme || url.host.isEmpty) return trimmed;

    final parts = url.pathSegments.where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return trimmed;
    parts[parts.length - 1] = Uri.encodeComponent(agentCode);

    return url.replace(path: '/${parts.join('/')}').toString();
  } catch (_) {
    return trimmed;
  }
}
