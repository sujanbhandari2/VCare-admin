bool isRequestAudioAttachment(String dataUrl, String name) {
  if (dataUrl.startsWith('data:audio/')) return true;
  return RegExp(
    r'\.(mp3|m4a|wav|webm|ogg|aac)$',
    caseSensitive: false,
  ).hasMatch(name);
}

bool isRequestImageAttachment(String dataUrl, String name) {
  if (dataUrl.startsWith('data:image/')) return true;
  return RegExp(
    r'\.(png|jpe?g|gif|webp|heic)$',
    caseSensitive: false,
  ).hasMatch(name);
}
