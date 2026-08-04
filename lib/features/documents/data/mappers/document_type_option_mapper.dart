import 'package:vcare_admin/features/documents/data/models/document_type_option_model.dart';
import 'package:vcare_admin/features/documents/domain/entities/document_type_option.dart';

extension DocumentTypeOptionModelMapper on DocumentTypeOptionModel {
  DocumentTypeOption toEntity() {
    return DocumentTypeOption(key: key, label: label);
  }
}

extension DocumentTypeOptionModelListMapper on List<DocumentTypeOptionModel> {
  List<DocumentTypeOption> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}
