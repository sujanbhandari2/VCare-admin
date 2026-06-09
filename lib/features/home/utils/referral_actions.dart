import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:flutter_template/features/home/utils/referral_utils.dart';
import 'package:flutter_template/features/profile/domain/entities/local_profile.dart';

/// Share/copy helpers — parity with vcareapp [useReferralActions].
class ReferralActions {
  ReferralActions(this.profile);

  final LocalProfile profile;

  String get username => referralUsernameFromEmail(profile.email);

  String get referralUrl => referralUrlFromEmail(profile.email);

  String get qrImageUrl => referralQrImageUrl(referralUrl, size: 320);

  String get shareText => '${profile.fullName} invited you to VCare';

  Future<void> copyReferralLink() async {
    await Clipboard.setData(ClipboardData(text: referralUrl));
    Fluttertoast.showToast(msg: 'Referral link copied');
  }

  Future<void> openQrImage() async {
    final launched = await launchUrlString(
      qrImageUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      Fluttertoast.showToast(msg: "Couldn't open QR image");
    }
  }

  Future<void> shareReferralLink() async {
    await copyReferralLink();
  }

  Future<void> openShareChannel({required String url}) async {
    final launched = await launchUrlString(
      url,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      Fluttertoast.showToast(msg: "Couldn't open share link");
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
