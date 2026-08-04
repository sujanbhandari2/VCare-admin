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
    this.documentType,
    this.createdBy,
    this.userId,
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
  final String? documentType;
  final String? createdBy;
  final String? userId;
  final String? sourceRouteName;
  final Map<String, String>? sourceRouteParameters;
  final String? uploadId;

  bool get hasSourceLink => sourceRouteName != null;

  bool get canOpen =>
      dataUrl.trim().isNotEmpty || previewUrl?.trim().isNotEmpty == true;

  String get imagePreviewUrl {
    final preview = previewUrl?.trim();
    if (preview != null && preview.isNotEmpty) {
      return preview;
    }
    return dataUrl;
  }

  DocumentItem copyWith({
    String? id,
    String? name,
    String? dataUrl,
    int? size,
    DocumentKind? kind,
    DocumentSource? source,
    String? sourceLabel,
    DateTime? createdAt,
    String? previewUrl,
    String? documentType,
    String? createdBy,
    String? userId,
    String? sourceRouteName,
    Map<String, String>? sourceRouteParameters,
    String? uploadId,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      dataUrl: dataUrl ?? this.dataUrl,
      size: size ?? this.size,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      createdAt: createdAt ?? this.createdAt,
      previewUrl: previewUrl ?? this.previewUrl,
      documentType: documentType ?? this.documentType,
      createdBy: createdBy ?? this.createdBy,
      userId: userId ?? this.userId,
      sourceRouteName: sourceRouteName ?? this.sourceRouteName,
      sourceRouteParameters:
          sourceRouteParameters ?? this.sourceRouteParameters,
      uploadId: uploadId ?? this.uploadId,
    );
  }
}
