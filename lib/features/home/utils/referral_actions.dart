import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:vcare_admin/features/home/domain/entities/referral_card_download_result.dart';
import 'package:vcare_admin/features/home/utils/referral_utils.dart';
import 'package:vcare_admin/features/profile/domain/entities/local_profile.dart';
import 'package:vcare_admin/shared/utils/qr_code_utils.dart';
import 'package:vcare_admin/shared/utils/widget_capture_utils.dart';

/// Share/copy helpers — parity with vcareapp [useReferralActions].
class ReferralActions {
  ReferralActions(
    this.profile, {
    GlobalKey? cardCaptureKey,
  }) : _cardCaptureKey = cardCaptureKey;

  final LocalProfile profile;
  final GlobalKey? _cardCaptureKey;

  String get username => referralUsernameFromEmail(profile.email);

  String get referralUrl => resolveReferralUrl(
        email: profile.email,
        referralLink: profile.referralLink,
      );

  String get shareText => '${profile.fullName} invited you to VCare';

  Future<void> copyReferralLink() async {
    await Clipboard.setData(ClipboardData(text: referralUrl));
  }

  Future<Uint8List?> captureCardBytes() async {
    final key = _cardCaptureKey;
    if (key == null) {
      return null;
    }
    return WidgetCaptureUtils.capturePng(key);
  }

  Future<ReferralCardDownloadResult> downloadCardToGallery() async {
    final bytes = await captureCardBytes();
    if (bytes == null) {
      return const ReferralCardDownloadResult(success: false);
    }

    final fileName =
        'vcare-referral-card-${DateTime.now().millisecondsSinceEpoch}';
    final saved = await WidgetCaptureUtils.saveToGallery(
      bytes,
      name: fileName,
    );

    return ReferralCardDownloadResult(
      success: saved,
      fileName: saved ? fileName : null,
    );
  }

  Future<bool> shareCardImage() async {
    final bytes = await captureCardBytes();
    if (bytes == null) {
      return false;
    }

    return WidgetCaptureUtils.sharePngBytes(
      bytes,
      fileName: 'vcare-referral-card.png',
      shareText: shareText,
    );
  }

  Future<bool> shareQrFallback() async {
    return QrCodeUtils.sharePng(
      referralUrl,
      fileName: 'vcare-referral-qr.png',
    );
  }

  Future<void> openShareChannel({required String url}) async {
    final launched = await launchUrlString(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('Could not open share link');
    }
  }

  static String whatsAppUrl(String referralUrl, String text) =>
      'https://wa.me/?text=${Uri.encodeComponent('$text $referralUrl')}';

  static String facebookUrl(String referralUrl) =>
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(referralUrl)}';

  static String twitterUrl(String referralUrl, String text) =>
      'https://twitter.com/intent/tweet?url=${Uri.encodeComponent(referralUrl)}&text=${Uri.encodeComponent(text)}';

  static String linkedInUrl(String referralUrl) =>
      'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(referralUrl)}';

  static String telegramUrl(String referralUrl, String text) =>
      'https://t.me/share/url?url=${Uri.encodeComponent(referralUrl)}&text=${Uri.encodeComponent(text)}';

  static String emailUrl(String referralUrl, String text) =>
      'mailto:?subject=${Uri.encodeComponent('Join me on VCare')}&body=${Uri.encodeComponent('$text\n\n$referralUrl')}';
}
