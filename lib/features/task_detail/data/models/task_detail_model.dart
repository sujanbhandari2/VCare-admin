/// Task record from `GET tasks/:id`.
///
/// Mirrors the web `TaskResponse`, which carries user ids for `assignedTo` and
/// `createdBy`. Some endpoints also nest the resolved user, so those objects are
/// parsed when present.
class TaskDetailModel {
  const TaskDetailModel({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
    this.category,
    this.categoryReferenceId,
    this.categoryReferenceLabel,
    this.clientId,
    this.assignedTo,
    this.assignee,
    this.createdBy,
    this.creator,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? status;
  final String? priority;
  final String? dueDate;
  final String? category;
  final String? categoryReferenceId;
  final String? categoryReferenceLabel;
  final String? clientId;
  final String? assignedTo;
  final TaskDetailPersonModel? assignee;
  final String? createdBy;
  final TaskDetailPersonModel? creator;
  final String? createdAt;
  final String? updatedAt;

  factory TaskDetailModel.fromJson(Map<String, dynamic> json) {
    return TaskDetailModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: _optionalString(json['description']),
      status: _optionalString(json['status']),
      priority: _optionalString(json['priority']),
      dueDate: _optionalString(json['dueDate']),
      category: _optionalString(json['category']),
      categoryReferenceId: _optionalString(json['categoryReferenceId']),
      categoryReferenceLabel: _optionalString(
        json['categoryReferenceLabel'] ?? json['referenceLabel'],
      ),
      clientId: _optionalString(json['clientId']),
      assignedTo: _optionalString(json['assignedTo']),
      assignee: TaskDetailPersonModel.parse(
        json['assignee'] ?? json['assignedUser'] ?? json['assignedTo'],
      ),
      createdBy: _optionalString(json['createdBy']),
      creator: TaskDetailPersonModel.parse(
        json['creator'] ?? json['createdByUser'] ?? json['createdBy'],
      ),
      createdAt: _optionalString(json['createdAt']),
      updatedAt: _optionalString(json['updatedAt']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

class TaskDetailPersonModel {
  const TaskDetailPersonModel({this.id, this.fullName, this.email});

  final String? id;
  final String? fullName;
  final String? email;

  factory TaskDetailPersonModel.fromJson(Map<String, dynamic> json) {
    final first = _optionalString(json['firstName']);
    final last = _optionalString(json['lastName']);
    final joined = [
      ?first,
      ?last,
    ].join(' ').trim();

    return TaskDetailPersonModel(
      id: _optionalString(json['id'] ?? json['userId'] ?? json['profileId']),
      fullName: _optionalString(
        json['fullName'] ?? json['name'] ?? json['displayName'],
      ) ??
          (joined.isEmpty ? null : joined),
      email: _optionalString(json['email']),
    );
  }

  /// Accepts either a nested user object or a bare user id string.
  static TaskDetailPersonModel? parse(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : TaskDetailPersonModel(id: trimmed);
    }
    if (value is Map) {
      return TaskDetailPersonModel.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
