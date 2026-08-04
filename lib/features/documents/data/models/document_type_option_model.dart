class DocumentTypeOptionModel {
  const DocumentTypeOptionModel({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  /// Parses `data` from document-types as a key → label map.
  static List<DocumentTypeOptionModel> listFromJson(dynamic data) {
    if (data is! Map) return const [];

    final options = <DocumentTypeOptionModel>[];
    for (final entry in data.entries) {
      final key = entry.key?.toString().trim() ?? '';
      final label = entry.value?.toString().trim() ?? '';
      if (key.isEmpty || label.isEmpty) continue;
      options.add(DocumentTypeOptionModel(key: key, label: label));
    }
    return options;
  }
}
