enum DocumentKind { image, audio, file }

enum DocumentSource { request, card, upload }

class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.name,
    required this.dataUrl,
    required this.size,
    required this.kind,
    required this.source,
    required this.sourceLabel,
    required this.createdAt,
    this.previewUrl,
    this.sourceRouteName,
    this.sourceRouteParameters,
    this.uploadId,
  });

  final String id;
  final String name;
  final String dataUrl;
  final int size;
  final DocumentKind kind;
  final DocumentSource source;
  final String sourceLabel;
  final DateTime createdAt;
  final String? previewUrl;
  final String? sourceRouteName;
  final Map<String, String>? sourceRouteParameters;
  final String? uploadId;

  bool get isDeletable => source == DocumentSource.upload;
  bool get hasSourceLink => sourceRouteName != null;
  bool get canOpen => dataUrl.trim().isNotEmpty || previewUrl?.trim().isNotEmpty == true;
  String get imagePreviewUrl {
    final preview = previewUrl?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview;
    }
    return dataUrl;
  }
}
