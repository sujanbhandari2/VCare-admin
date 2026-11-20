/// Note status from the task notes API.
enum MyTaskNoteStatus {
  open,
  inProgress,
  snoozed,
  completed,
  cancelled;

  String get label => switch (this) {
    MyTaskNoteStatus.open => 'Open',
    MyTaskNoteStatus.inProgress => 'In Progress',
    MyTaskNoteStatus.snoozed => 'Snoozed',
    MyTaskNoteStatus.completed => 'Completed',
    MyTaskNoteStatus.cancelled => 'Cancelled',
  };

  static MyTaskNoteStatus? fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'OPEN':
        return MyTaskNoteStatus.open;
      case 'IN_PROGRESS':
        return MyTaskNoteStatus.inProgress;
      case 'SNOOZED':
        return MyTaskNoteStatus.snoozed;
      case 'COMPLETED':
        return MyTaskNoteStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return MyTaskNoteStatus.cancelled;
      default:
        return null;
    }
  }
}

/// A note on a task from `GET/POST /tasks/:id/notes`.
class MyTaskNote {
  const MyTaskNote({
    required this.id,
    required this.taskId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.status,
    this.authorId,
    this.authorLabel,
    this.authorFirstName,
    this.authorLastName,
  });

  final String id;
  final String taskId;
  final String text;
  final MyTaskNoteStatus? status;
  final String? authorId;
  final String? authorLabel;
  final String? authorFirstName;
  final String? authorLastName;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEdited =>
      updatedAt.isAfter(createdAt.add(const Duration(seconds: 1)));

  String get displayAuthor {
    final label = authorLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final joined = [
      authorFirstName?.trim(),
      authorLastName?.trim(),
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    if (joined.isNotEmpty) return joined;
    return authorId?.trim().isNotEmpty == true ? authorId! : 'Unknown';
  }
}
