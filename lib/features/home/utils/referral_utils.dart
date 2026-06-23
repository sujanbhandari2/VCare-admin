// Referral link, QR, and slug helpers.
// parity: vcare-agent-app-2.0/src/features/id-card/hooks/useReferralActions.ts

final _referralSlugPattern = RegExp(r'^[a-z0-9._-]{3,30}$');

const referralUrlPrefix = 'vcare.app/refer/';

String referralUsernameFromEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email.toLowerCase();
  return email.substring(0, at).toLowerCase();
}

String sanitizeReferralSlug(String raw) {
  final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  return cleaned.length > 30 ? cleaned.substring(0, 30) : cleaned;
}

String? validateReferralSlug(String slug) {
  if (slug.isEmpty) return "Username can't be empty";
  if (slug.length < 3) return 'Use at least 3 characters';
  if (slug.length > 30) return 'Use at most 30 characters';
  if (!_referralSlugPattern.hasMatch(slug)) {
    return 'Only lowercase letters, numbers, dot, underscore or hyphen';
  }
  return null;
}

String referralUrlFromSlug(String slug) => 'https://$referralUrlPrefix$slug';

String referralUrlFromEmail(String email) =>
    referralUrlFromSlug(referralUsernameFromEmail(email));

String referralQrImageUrl(String referralUrl, {int size = 160}) {
  return 'https://api.qrserver.com/v1/create-qr-code/'
      '?size=${size}x$size&margin=0&data=${Uri.encodeComponent(referralUrl)}';
}
