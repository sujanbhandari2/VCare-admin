/// Referral link and QR helpers — parity with vcareapp [useReferralActions].
String referralUsernameFromEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email.toLowerCase();
  return email.substring(0, at).toLowerCase();
}

String referralUrlFromEmail(String email) {
  final username = referralUsernameFromEmail(email);
  return 'https://vcare.app/refer/$username';
}

String referralQrImageUrl(String referralUrl, {int size = 160}) {
  return 'https://api.qrserver.com/v1/create-qr-code/'
      '?size=${size}x$size&margin=0&data=${Uri.encodeComponent(referralUrl)}';
}
