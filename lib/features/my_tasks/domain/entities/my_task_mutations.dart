import 'package:vcare_admin/features/my_tasks/domain/entities/my_task.dart';

/// Payload for `POST /tasks`.
class MyTaskCreateRequest {
  const MyTaskCreateRequest({
    required this.title,
    this.description,
    this.status = MyTaskStatus.toDo,
    this.priority = MyTaskPriority.medium,
    this.dueDateIso,
    this.assignedTo,
    this.category,
    this.categoryReferenceId,
    this.clientId,
    this.initialNote,
  });

  final String title;
  final String? description;
  final MyTaskStatus status;
  final MyTaskPriority priority;
  final String? dueDateIso;
  final String? assignedTo;
  final String? category;
  final String? categoryReferenceId;
  final String? clientId;

  /// Optional note created after the task via the notes API.
  final String? initialNote;

  Map<String, dynamic> toJson() {
    final trimmedDescription = description?.trim();
    final trimmedAssignee = assignedTo?.trim();
    final trimmedDue = dueDateIso?.trim();
    final trimmedCategory = category?.trim();
    final trimmedRef = categoryReferenceId?.trim();
    final trimmedClient = clientId?.trim();

    return {
      'title': title.trim(),
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription,
      'status': status.apiValue,
      'priority': priority.apiValue,
      if (trimmedDue != null && trimmedDue.isNotEmpty) 'dueDate': trimmedDue,
      if (trimmedAssignee != null && trimmedAssignee.isNotEmpty)
        'assignedTo': trimmedAssignee,
      if (trimmedCategory != null && trimmedCategory.isNotEmpty)
        'category': trimmedCategory,
      if (trimmedRef != null && trimmedRef.isNotEmpty)
        'categoryReferenceId': trimmedRef,
      if (trimmedClient != null && trimmedClient.isNotEmpty)
        'clientId': trimmedClient,
    };
  }
}

/// Payload for `PATCH /tasks/:id`.
class MyTaskUpdateRequest {
  const MyTaskUpdateRequest({
    this.title,
    this.description,
    this.clearDescription = false,
    this.status,
    this.priority,
    this.dueDateIso,
    this.clearDueDate = false,
    this.assignedTo,
    this.clearAssignedTo = false,
    this.category,
    this.clearCategory = false,
    this.categoryReferenceId,
    this.clearCategoryReferenceId = false,
    this.clientId,
    this.clearClientId = false,
  });

  final String? title;
  final String? description;
  final bool clearDescription;
  final MyTaskStatus? status;
  final MyTaskPriority? priority;
  final String? dueDateIso;
  final bool clearDueDate;
  final String? assignedTo;
  final bool clearAssignedTo;
  final String? category;
  final bool clearCategory;
  final String? categoryReferenceId;
  final bool clearCategoryReferenceId;
  final String? clientId;
  final bool clearClientId;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{};

    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      body['title'] = trimmedTitle;
    }

    if (clearDescription) {
      body['description'] = null;
    } else if (description != null) {
      final trimmed = description!.trim();
      body['description'] = trimmed.isEmpty ? null : trimmed;
    }

    if (status != null) body['status'] = status!.apiValue;
    if (priority != null) body['priority'] = priority!.apiValue;

    if (clearDueDate) {
      body['dueDate'] = null;
    } else if (dueDateIso != null) {
      body['dueDate'] = dueDateIso;
    }

    if (clearAssignedTo) {
      body['assignedTo'] = null;
    } else if (assignedTo != null) {
      final trimmed = assignedTo!.trim();
      body['assignedTo'] = trimmed.isEmpty ? null : trimmed;
    }

    if (clearCategory) {
      body['category'] = null;
    } else if (category != null) {
      body['category'] = category;
    }

    if (clearCategoryReferenceId) {
      body['categoryReferenceId'] = null;
    } else if (categoryReferenceId != null) {
      body['categoryReferenceId'] = categoryReferenceId;
    }

    if (clearClientId) {
      body['clientId'] = null;
    } else if (clientId != null) {
      body['clientId'] = clientId;
    }

    return body;
  }
}

/// Payload for `PATCH /tasks/:id/snooze`.
class MyTaskSnoozeRequest {
  const MyTaskSnoozeRequest({required this.snoozedTillIso, this.notes});

  /// ISO datetime, or `null` to resume (clear snooze).
  final String? snoozedTillIso;
  final String? notes;

  Map<String, dynamic> toJson() {
    final trimmedNotes = notes?.trim();
    return {
      'snoozedTill': snoozedTillIso,
      if (trimmedNotes != null && trimmedNotes.isNotEmpty)
        'notes': trimmedNotes,
    };
  }
}
