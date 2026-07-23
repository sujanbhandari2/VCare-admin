/// A selectable document type from `GET /files/document-types`.
class DocumentTypeOption {
  const DocumentTypeOption({
    required this.key,
    required this.label,
  });

  /// API map key (e.g. `W9_FORM`, `OTHER`).
  final String key;

  /// Display label sent as `documentType` on upload (e.g. `W-9 Form`).
  final String label;
}
