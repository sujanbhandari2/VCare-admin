/// Raw task payload from `GET /tasks` / `GET /tasks/:id`.
class MyTaskModel {
  const MyTaskModel({
    required this.id,
    required this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
    this.snoozedTill,
    this.category,
    this.categoryReferenceId,
    this.clientId,
    this.client,
    this.clientName,
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
  final String? snoozedTill;
  final String? category;
  final String? categoryReferenceId;
  final String? clientId;
  final MyTaskClientModel? client;
  final String? clientName;
  final String? assignedTo;
  final MyTaskPersonModel? assignee;
  final String? createdBy;
  final MyTaskPersonModel? creator;
  final String? createdAt;
  final String? updatedAt;

  factory MyTaskModel.fromJson(Map<String, dynamic> json) {
    return MyTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: _optionalString(json['description']),
      status: _optionalString(json['status']),
      priority: _optionalString(json['priority']),
      dueDate: _optionalString(json['dueDate']),
      snoozedTill: _optionalString(json['snoozedTill']),
      category: _optionalString(json['category']),
      categoryReferenceId: _optionalString(json['categoryReferenceId']),
      clientId: _optionalString(json['clientId']),
      client: json['client'] is Map
          ? MyTaskClientModel.fromJson(
              Map<String, dynamic>.from(json['client'] as Map),
            )
          : null,
      clientName: _optionalString(json['clientName']),
      assignedTo: _optionalString(json['assignedTo']),
      assignee: MyTaskPersonModel.parse(
        json['assignee'] ?? json['assignedUser'] ?? json['assignedTo'],
      ),
      createdBy: _optionalString(json['createdBy']),
      creator: MyTaskPersonModel.parse(
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

class MyTaskPersonModel {
  const MyTaskPersonModel({
    this.id,
    this.fullName,
    this.email,
    this.isInactive = false,
  });

  final String? id;
  final String? fullName;
  final String? email;
  final bool isInactive;

  factory MyTaskPersonModel.fromJson(Map<String, dynamic> json) {
    final first = _optionalString(json['firstName']);
    final last = _optionalString(json['lastName']);
    final joined = [?first, ?last].join(' ').trim();

    return MyTaskPersonModel(
      id: _optionalString(json['id'] ?? json['userId'] ?? json['profileId']),
      fullName:
          _optionalString(
            json['fullName'] ?? json['name'] ?? json['displayName'],
          ) ??
          (joined.isEmpty ? null : joined),
      email: _optionalString(json['email']),
      isInactive: json['isInactive'] == true || json['isDeleted'] == true,
    );
  }

  static MyTaskPersonModel? parse(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : MyTaskPersonModel(id: trimmed);
    }
    if (value is Map) {
      return MyTaskPersonModel.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }
}

class MyTaskClientModel {
  const MyTaskClientModel({
    required this.id,
    required this.name,
    this.email,
    this.clientType,
    this.groupName,
  });

  final String id;
  final String name;
  final String? email;
  final String? clientType;
  final String? groupName;

  factory MyTaskClientModel.fromJson(Map<String, dynamic> json) {
    return MyTaskClientModel(
      id: json['id']?.toString() ?? '',
      name: _optionalString(json['name'] ?? json['groupName']) ?? '',
      email: _optionalString(json['email']),
      clientType: _optionalString(json['clientType']),
      groupName: _optionalString(json['groupName']),
    );
  }
}

class MyTaskMetricsModel {
  const MyTaskMetricsModel({this.open = 0, this.overdue = 0, this.dueSoon = 0});

  final int open;
  final int overdue;
  final int dueSoon;

  factory MyTaskMetricsModel.fromJson(Map<String, dynamic> json) {
    return MyTaskMetricsModel(
      open: _asInt(json['open']),
      overdue: _asInt(json['overdue']),
      dueSoon: _asInt(json['dueSoon']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class MyTaskNoteModel {
  const MyTaskNoteModel({
    required this.id,
    required this.taskId,
    required this.note,
    this.status,
    this.createdBy,
    this.creator,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String taskId;
  final String note;
  final String? status;
  final String? createdBy;
  final MyTaskPersonModel? creator;
  final String? createdAt;
  final String? updatedAt;

  factory MyTaskNoteModel.fromJson(Map<String, dynamic> json) {
    return MyTaskNoteModel(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      status: _optionalString(json['status']),
      createdBy: _optionalString(json['createdBy']),
      creator: MyTaskPersonModel.parse(json['creator']),
      createdAt: _optionalString(json['createdAt']),
      updatedAt: _optionalString(json['updatedAt']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
