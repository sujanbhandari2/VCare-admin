import 'package:vcare_admin/shared/models/loadable_list_item.dart';

class AgentFile implements LoadableListItem {
  const AgentFile({
    required this.id,
    required this.name,
    required this.url,
    required this.createdAt,
    this.userId,
    this.tenantId,
    this.note,
    this.date,
    this.category,
    this.categoryReferenceId,
    this.subCategoryReferenceId,
    this.createdBy,
  });

  final String id;
  final String name;
  final String url;
  final DateTime createdAt;
  final String? userId;
  final String? tenantId;
  final String? note;
  final String? date;
  final String? category;
  final String? categoryReferenceId;
  final String? subCategoryReferenceId;
  final String? createdBy;
}
