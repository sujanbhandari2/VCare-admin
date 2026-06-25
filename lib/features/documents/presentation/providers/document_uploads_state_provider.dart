import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/documents/domain/entities/document_item.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';

part 'document_uploads_state_provider.g.dart';

@Riverpod(keepAlive: true)
class DocumentUploadsStateNotifier extends _$DocumentUploadsStateNotifier {
  @override
  List<DocumentItem> build() => const [];

  void addUpload({
    required String name,
    required String dataUrl,
    required int size,
  }) {
    final id = 'up-${DateTime.now().millisecondsSinceEpoch}';
    final item = DocumentItem(
      id: id,
      uploadId: id,
      name: name,
      dataUrl: dataUrl,
      size: size,
      kind: documentKindOf(dataUrl, name),
      source: DocumentSource.upload,
      sourceLabel: 'Uploaded',
      createdAt: DateTime.now(),
    );

    state = [item, ...state];
  }

  void removeUpload(String uploadId) {
    state = state.where((item) => item.uploadId != uploadId).toList();
  }
}
