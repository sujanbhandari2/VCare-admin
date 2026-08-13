import 'package:vcare_admin/features/cases/data/models/case_file_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_file.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';

extension CaseFileModelMapper on CaseFileModel {
  CaseFile toEntity({required String hostBaseUrl}) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Untitled';
    final uploadedAt = createdAt?.trim().isNotEmpty == true
        ? createdAt!
        : (date ?? '');

    return CaseFile(
      id: id,
      name: displayName,
      type: _fileTypeLabel(displayName),
      size: size?.trim().isNotEmpty == true ? size!.trim() : '',
      uploadedAt: uploadedAt,
      uploadedBy: createdBy ?? '',
      url: url == null || url!.trim().isEmpty
          ? null
          : resolveDocumentUrl(url!, hostBaseUrl),
    );
  }
}

String _fileTypeLabel(String fileName) {
  final trimmed = fileName.trim();
  final dot = trimmed.lastIndexOf('.');
  if (dot < 0 || dot == trimmed.length - 1) return 'File';
  return trimmed.substring(dot + 1).toUpperCase();
}
