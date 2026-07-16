import 'package:vcare_admin/features/documents/data/models/agent_file_model.dart';
import 'package:vcare_admin/features/documents/domain/entities/agent_file.dart';
import 'package:vcare_admin/features/documents/utils/documents_utils.dart';

extension AgentFileModelMapper on AgentFileModel {
  AgentFile toEntity({required String hostBaseUrl}) {
    final parsedCreatedAt = DateTime.tryParse(createdAt ?? '') ?? DateTime.now();

    return AgentFile(
      id: id,
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Untitled',
      url: resolveDocumentUrl(url ?? '', hostBaseUrl),
      previewLink: previewLink?.trim().isNotEmpty == true
          ? resolveDocumentUrl(previewLink!, hostBaseUrl)
          : null,
      createdAt: parsedCreatedAt,
      userId: userId,
      tenantId: tenantId,
      note: note,
      date: date,
      category: category,
      categoryReferenceId: categoryReferenceId,
      subCategoryReferenceId: subCategoryReferenceId,
      createdBy: createdBy,
    );
  }
}
