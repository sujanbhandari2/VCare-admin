import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';
import 'package:vcare_admin/features/vcare_sync/data/vcare_catalog.dart';

/// Local upload seed — parity with vcareapp `uploads-store.ts` samples.
class DocumentUploadSeed {
  const DocumentUploadSeed({
    required this.id,
    required this.name,
    required this.dataUrl,
    required this.size,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String dataUrl;
  final int size;
  final DateTime createdAt;

  DocumentItem toDocumentItem() {
    return DocumentItem(
      id: id,
      uploadId: id,
      name: name,
      dataUrl: dataUrl,
      size: size,
      kind: documentKindOf(dataUrl, name),
      source: DocumentSource.upload,
      sourceLabel: 'Uploaded',
      createdAt: createdAt,
    );
  }
}

abstract final class DocumentsSeed {
  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));

  static final uploads = <DocumentUploadSeed>[
    DocumentUploadSeed(
      id: 'seed-agreement-signed',
      name: 'Agreement - Signed.pdf',
      dataUrl:
          'data:application/pdf;base64,JVBERi0xLjQKJeLjz9MKMSAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgMiAwIFI+PgplbmRvYmoKMiAwIG9iago8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PgplbmRvYmoKMyAwIG9iago8PC9UeXBlL1BhZ2UvUGFyZW50IDIgMCBSL01lZGlhQm94WzAgMCAzMDAgMTQ0XS9SZXNvdXJjZXM8PD4+L0NvbnRlbnRzIDQgMCBSPj4KZW5kb2JqCjQgMCBvYmoKPDwvTGVuZ3RoIDU0Pj4Kc3RyZWFtCkJUIC9GMSAxMiBUZiA1MCA4MCBUZCAoQWdyZWVtZW50IFNpZ25lZCkgVGogRVQKZW5kc3RyZWFtCmVuZG9iagp4cmVmCjAgNQowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwMTAgMDAwMDAgbiAKMDAwMDAwMDA1NyAwMDAwMCBuIAowMDAwMDAwMTA0IDAwMDAwIG4gCjAwMDAwMDAxODggMDAwMDAgbiAKdHJhaWxlcgo8PC9TaXplIDUvUm9vdCAxIDAgUj4+CnN0YXJ0eHJlZgoyOTAKJSVFT0YK',
      size: 142336,
      createdAt: _daysAgo(1),
    ),
    DocumentUploadSeed(
      id: 'seed-receipt',
      name: 'Pharmacy Receipt.jpg',
      dataUrl:
          "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='400' height='560'><rect width='100%25' height='100%25' fill='%23f8fafc'/><rect x='30' y='30' width='340' height='500' rx='12' fill='white' stroke='%23e2e8f0'/><text x='200' y='90' text-anchor='middle' font-family='Arial' font-size='22' font-weight='700' fill='%230f172a'>VCare Pharmacy</text></svg>",
      size: 24576,
      createdAt: _daysAgo(20),
    ),
  ];

  static List<DocumentItem> catalogItems() {
    return VCareCatalog.documents.map((document) {
      final kind = switch (document.kind) {
        'Images' => DocumentKind.image,
        'Voice' => DocumentKind.audio,
        _ => DocumentKind.file,
      };

      return DocumentItem(
        id: 'catalog-${document.name.hashCode}',
        name: document.name,
        dataUrl: '',
        size: _parseSizeLabel(document.sizeLabel),
        kind: kind,
        source: document.sourceLabel.contains('Referral')
            ? DocumentSource.card
            : DocumentSource.request,
        sourceLabel: document.sourceLabel,
        createdAt: document.createdAt,
        sourceRouteName: document.sourceLabel.contains('Referral')
            ? AppRouter.idCardName
            : AppRouter.requestDetailName,
        sourceRouteParameters: document.sourceLabel.contains('Referral')
            ? null
            : const {'id': 'r-001'},
      );
    }).toList();
  }

  static int _parseSizeLabel(String label) {
    final match = RegExp(r'([\d.]+)\s*(KB|MB|B)', caseSensitive: false)
        .firstMatch(label.trim());
    if (match == null) return 0;

    final value = double.tryParse(match.group(1) ?? '') ?? 0;
    return switch (match.group(2)?.toUpperCase()) {
      'KB' => (value * 1024).round(),
      'MB' => (value * 1024 * 1024).round(),
      _ => value.round(),
    };
  }
}
