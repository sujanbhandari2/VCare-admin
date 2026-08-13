import 'package:vcare_admin/features/cases/data/models/case_assignee_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_assignee.dart';

extension CaseAssigneeModelMapper on CaseAssigneeModel {
  CaseAssignee toEntity() {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final computedDisplay = [
      first,
      last,
    ].where((part) => part.isNotEmpty).join(' ');

    return CaseAssignee(
      id: id,
      firstName: first,
      lastName: last,
      email: email,
      role: role ?? '',
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (computedDisplay.isNotEmpty
                ? computedDisplay
                : (email.isNotEmpty ? email : null)),
      profileImage: profileImage ?? profilePreviewLink,
    );
  }
}
