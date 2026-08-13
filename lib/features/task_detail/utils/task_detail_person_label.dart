import 'package:vcare_admin/features/task_detail/domain/entities/task_detail.dart';
import 'package:vcare_admin/features/users/domain/entities/associated_user.dart';

/// Resolves a task's user reference to a display name.
///
/// Tasks carry `assignedTo` / `createdBy` as user ids, so the name comes from
/// the loaded team members — the same lookup the web drawer does. Unlike the
/// web, an unresolved id falls back to [fallback] instead of showing the raw
/// uuid.
String resolveTaskDetailPersonLabel(
  TaskDetailPerson? person,
  List<AssociatedUser> users, {
  required String fallback,
}) {
  if (person == null) return fallback;

  final name = person.name?.trim();
  if (name != null && name.isNotEmpty) return name;

  final id = person.id.trim();
  if (id.isEmpty) return fallback;

  for (final user in users) {
    if (user.id == id) return user.displayName;
  }

  return fallback;
}
