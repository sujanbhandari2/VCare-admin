import 'package:vcare_admin/features/clients/data/mappers/client_mapper_utils.dart';
import 'package:vcare_admin/features/clients/data/models/client_document_model.dart';
import 'package:vcare_admin/features/clients/domain/entities/client.dart';

extension ClientDocumentModelMapper on ClientDocumentModel {
  ClientFile toEntity({required String hostBaseUrl}) {
    final uploadedAt = createdAt?.trim().isNotEmpty == true
        ? createdAt!
        : (date ?? '');

    return ClientFile(
      id: id,
      name: name?.trim().isNotEmpty == true ? name!.trim() : 'Untitled',
      size: '',
      uploadedAt: uploadedAt,
      url: resolveClientDocumentUrl(url ?? '', hostBaseUrl),
      previewLink: previewLink?.trim().isNotEmpty == true
          ? resolveClientDocumentUrl(previewLink!, hostBaseUrl)
          : null,
      mime: mimeTypeFromFileName(name),
    );
  }
}
