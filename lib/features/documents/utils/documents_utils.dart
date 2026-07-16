import 'package:intl/intl.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/cases/utils/request_attachments.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_filter.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';

DocumentKind documentKindOf(String dataUrl, String name) {
  if (isDocumentImage(dataUrl, name)) {
    return DocumentKind.image;
  }
  if (isRequestAudioAttachment(dataUrl, name)) {
    return DocumentKind.audio;
  }
  return DocumentKind.file;
}

bool isDocumentImage(String url, String name) {
  if (isRequestImageAttachment(url, name)) return true;

  final normalized = url.trim().toLowerCase();
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return _hasImageExtension(url) || _hasImageExtension(name);
  }

  return false;
}

bool isDocumentPdf(String url, String name) {
  if (url.startsWith('data:application/pdf')) return true;
  return url.toLowerCase().endsWith('.pdf') ||
      name.toLowerCase().endsWith('.pdf');
}

bool isDocumentNetworkUrl(String url) {
  final normalized = url.trim().toLowerCase();
  return normalized.startsWith('http://') || normalized.startsWith('https://');
}

String resolveDocumentUrl(String url, String hostBaseUrl) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.scheme.startsWith('http')) {
    return trimmed;
  }

  final root = hostBaseUrl.endsWith('/') ? hostBaseUrl : '$hostBaseUrl/';
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '${root}api/$path';
}

String? _nonEmptyDocumentUrl(String? url) {
  final trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

DocumentItem documentItemFromAgentFile(AgentFile file) {
  final kind = documentKindOf(file.url, file.name);
  final source = _sourceFromCategory(file.category);
  final sourceLabel = _sourceLabel(file);

  return DocumentItem(
    id: file.id,
    name: file.name,
    dataUrl: file.url,
    previewUrl: _nonEmptyDocumentUrl(file.previewLink),
    size: 0,
    kind: kind,
    source: source,
    sourceLabel: sourceLabel,
    createdAt: file.createdAt,
    sourceRouteName: source == DocumentSource.request
        ? AppRouter.clientDetailName
        : null,
    sourceRouteParameters: source == DocumentSource.request &&
            file.categoryReferenceId?.trim().isNotEmpty == true
        ? {'id': file.categoryReferenceId!.trim()}
        : null,
  );
}

DocumentSource _sourceFromCategory(String? category) {
  final normalized = category?.trim().toUpperCase();
  if (normalized == 'CLIENT') return DocumentSource.request;
  if (normalized == 'CARD') return DocumentSource.card;
  if (normalized == 'DEAL') return DocumentSource.upload;
  return DocumentSource.upload;
}

String _sourceLabel(AgentFile file) {
  return switch (file.category?.trim().toUpperCase()) {
    'CLIENT' => 'Client document',
    'CARD' => 'Digital ID Card',
    _ => 'Uploaded',
  };
}

bool _hasImageExtension(String value) {
  return RegExp(
    r'\.(png|jpe?g|gif|webp|heic|bmp)$',
    caseSensitive: false,
  ).hasMatch(value.trim());
}

String todayIsoDate() {
  return DateTime.now().toIso8601String().split('T').first;
}

String mimeTypeFromFileName(String? fileName) {
  final name = fileName?.trim().toLowerCase();
  if (name == null || name.isEmpty) return 'application/octet-stream';

  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.gif')) return 'image/gif';
  if (name.endsWith('.webp')) return 'image/webp';
  if (name.endsWith('.bmp')) return 'image/bmp';
  if (name.endsWith('.svg')) return 'image/svg+xml';
  if (name.endsWith('.pdf')) return 'application/pdf';
  if (name.endsWith('.doc')) return 'application/msword';
  if (name.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (name.endsWith('.txt')) return 'text/plain';
  if (name.endsWith('.mp3')) return 'audio/mpeg';
  if (name.endsWith('.wav')) return 'audio/wav';
  if (name.endsWith('.m4a')) return 'audio/mp4';
  if (name.endsWith('.webm')) return 'audio/webm';
  if (name.endsWith('.ogg')) return 'audio/ogg';
  return 'application/octet-stream';
}

String formatDocumentDate(DateTime date) {
  return DateFormat.yMMMd().format(date.toLocal());
}

String formatDocumentSize(int bytes) {
  if (bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

bool documentMatchesFilter(DocumentItem item, DocumentFilter filter) {
  return switch (filter) {
    DocumentFilter.all => true,
    DocumentFilter.images => item.kind == DocumentKind.image,
    DocumentFilter.voice => item.kind == DocumentKind.audio,
    DocumentFilter.files => item.kind == DocumentKind.file,
  };
}

Map<DocumentFilter, int> documentFilterCounts(List<DocumentItem> items) {
  return {
    DocumentFilter.all: items.length,
    DocumentFilter.images:
        items.where((item) => item.kind == DocumentKind.image).length,
    DocumentFilter.voice:
        items.where((item) => item.kind == DocumentKind.audio).length,
    DocumentFilter.files:
        items.where((item) => item.kind == DocumentKind.file).length,
  };
}

List<DocumentItem> filterDocuments({
  required List<DocumentItem> items,
  required DocumentFilter filter,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return items.where((item) {
    if (!documentMatchesFilter(item, filter)) return false;
    if (normalizedQuery.isEmpty) return true;
    return item.name.toLowerCase().contains(normalizedQuery) ||
        item.sourceLabel.toLowerCase().contains(normalizedQuery);
  }).toList();
}
