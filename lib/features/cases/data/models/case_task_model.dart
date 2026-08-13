/// Task record from `GET/POST/PATCH /tasks`.
class CaseTaskModel {
  const CaseTaskModel({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.priority,
    this.assignedTo,
    this.assignee,
    this.dueDate,
    this.category,
    this.categoryReferenceId,
    this.clientId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final String? assignedTo;
  final CaseTaskAssigneeModel? assignee;
  final String? dueDate;
  final String? category;
  final String? categoryReferenceId;
  final String? clientId;
  final String? createdAt;
  final String? updatedAt;

  factory CaseTaskModel.fromJson(Map<String, dynamic> json) {
    final assigneeRaw = json['assignee'];

    return CaseTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: _optionalString(json['description']),
      status: _optionalString(json['status']),
      priority: _optionalString(json['priority']),
      assignedTo: _optionalString(json['assignedTo']),
      assignee: assigneeRaw is Map
          ? CaseTaskAssigneeModel.fromJson(
              Map<String, dynamic>.from(assigneeRaw),
            )
          : CaseTaskAssigneeModel.parsePerson(assigneeRaw),
      dueDate: _optionalString(json['dueDate']),
      category: _optionalString(json['category']),
      categoryReferenceId: _optionalString(json['categoryReferenceId']),
      clientId: _optionalString(json['clientId']),
      createdAt: _optionalString(json['createdAt']),
      updatedAt: _optionalString(json['updatedAt']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

class CaseTaskAssigneeModel {
  const CaseTaskAssigneeModel({
    this.id,
    this.fullName,
    this.email,
  });

  final String? id;
  final String? fullName;
  final String? email;

  factory CaseTaskAssigneeModel.fromJson(Map<String, dynamic> json) {
    return CaseTaskAssigneeModel(
      id: _optionalString(json['id']),
      fullName: _optionalString(json['fullName'] ?? json['name']),
      email: _optionalString(json['email']),
    );
  }

  static CaseTaskAssigneeModel? parsePerson(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return CaseTaskAssigneeModel(id: trimmed);
    }
    if (value is Map) {
      return CaseTaskAssigneeModel.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
