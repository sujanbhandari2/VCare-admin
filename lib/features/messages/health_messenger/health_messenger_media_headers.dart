import 'package:health_messenger_ui/lib/health_messenger_ui.dart';

/// Request headers for chat attachment downloads.
///
/// Attachments are usually served from object storage rather than the chat API.
/// Those hosts reject a request that carries `Authorization` / `X-Api-Key`
/// (S3-style backends answer 400), which renders every bubble as
/// "Unable to load image". The web widget loads media through plain `<img>`
/// tags with no auth headers, so headers are only sent when the media lives on
/// the chat API origin itself.
Map<String, String> healthMessengerMediaHeaders({
  required String mediaUrl,
  required String apiBaseUrl,
  ChatAuth? auth,
}) {
  if (auth == null) {
    return const {};
  }
  if (!healthMessengerMediaIsChatApiOrigin(
    mediaUrl: mediaUrl,
    apiBaseUrl: apiBaseUrl,
  )) {
    return const {};
  }
  return auth.toApiHeaders();
}

/// Whether [mediaUrl] is served by the same host as [apiBaseUrl].
bool healthMessengerMediaIsChatApiOrigin({
  required String mediaUrl,
  required String apiBaseUrl,
}) {
  final mediaHost = Uri.tryParse(mediaUrl.trim())?.host.toLowerCase() ?? '';
  final apiHost = Uri.tryParse(apiBaseUrl.trim())?.host.toLowerCase() ?? '';
  if (mediaHost.isEmpty || apiHost.isEmpty) {
    return false;
  }
  return mediaHost == apiHost;
}
