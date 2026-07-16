import 'package:vcare_admin/core/config/flavor/configuration.dart';
import 'package:vcare_admin/core/config/flavor/flavor.dart';

const _uatCardSecureBase = 'https://fts-uat.cardconnect.com';
const _liveCardSecureBase = 'https://fts.cardconnect.com';

bool isCardConnectLiveEnvironment([Flavor? flavor]) {
  return (flavor ?? Configuration.of().flavor) == Flavor.prod;
}

/// CardSecure tokenize endpoint — same FTS site as admin hosted tokenizer.
String getCardSecureTokenizeUrl([Flavor? flavor]) {
  final base = isCardConnectLiveEnvironment(flavor)
      ? _liveCardSecureBase
      : _uatCardSecureBase;
  return '$base/cardsecure/api/v1/ccn/tokenize';
}
