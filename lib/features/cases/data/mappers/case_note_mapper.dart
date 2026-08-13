import 'package:vcare_admin/features/cases/data/models/case_note_model.dart';
import 'package:vcare_admin/features/cases/domain/entities/case_note.dart';
import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';

extension CaseNoteModelMapper on CaseNoteModel {
  CaseNote toEntity({String? currentUserId}) {
    final createdById = createdBy?.id;
    final authorName = _resolveAuthorName(createdBy);
    final status = _resolveNoteStatus(status: this.status, accessType: accessType);
    final canModify =
        status != null &&
        currentUserId != null &&
        currentUserId.trim().isNotEmpty &&
        createdById != null &&
        createdById.trim().toLowerCase() ==
            currentUserId.trim().toLowerCase() &&
        externalInviteId == null;

    return CaseNote(
      id: id,
      content: note,
      createdAt: createdAt ?? '',
      authorName: authorName,
      authorInitials: _authorInitials(authorName),
      status: status,
      accessType: accessType,
      createdById: createdById,
      authorProfilePreviewLink: createdBy?.profilePreviewLink,
      files: files.map((file) => file.toEntity()).toList(growable: false),
      tags: tags.map((tag) => tag.toEntity()).toList(growable: false),
      externalInviteId: externalInviteId,
      canEdit: canModify,
      canDelete: canModify,
    );
  }
}

extension CaseNoteFileModelMapper on CaseNoteFileModel {
  CaseNoteFile toEntity() {
    return CaseNoteFile(
      id: id,
      name: name,
      url: url,
      note: note,
    );
  }
}

extension CaseNoteTagModelMapper on CaseNoteTagModel {
  CaseNoteTag toEntity() {
    return CaseNoteTag(
      taggedUserId: taggedUserId,
      taggedEmail: taggedEmail,
      taggedName: taggedName,
    );
  }
}

extension CaseNoteTagUserModelMapper on CaseNoteTagUserModel {
  CaseNoteTagUser toEntity() {
    return CaseNoteTagUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      profileImage: profileImage,
      role: role,
    );
  }
}

String _resolveAuthorName(CaseNoteAuthorModel? createdBy) {
  if (createdBy == null) return 'Team member';
  final name = createdBy.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return 'Team member';
}

String _authorInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  if (parts.isEmpty) return 'TM';
  final value = parts.first;
  if (value.length >= 2) return value.substring(0, 2).toUpperCase();
  return value.toUpperCase();
}

CaseStatus? _resolveNoteStatus({String? status, String? accessType}) {
  final fromStatus = _mapApiValueToNoteStatus(status);
  if (fromStatus != null) return fromStatus;
  return _mapWorkflowStatusFromAccessType(accessType);
}

CaseStatus? _mapApiValueToNoteStatus(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'new':
      return CaseStatus.newCase;
    case 'requested':
      return CaseStatus.requested;
    case 'in_progress':
    case 'in progress':
      return CaseStatus.inProgress;
    case 'closed':
      return CaseStatus.closed;
    case 'deleted':
      return CaseStatus.deleted;
  }

  switch (value.trim().toUpperCase()) {
    case 'NEW':
      return CaseStatus.newCase;
    case 'REQUESTED':
    case 'OPEN':
      return CaseStatus.requested;
    case 'IN_PROGRESS':
    case 'ACTIVE':
      return CaseStatus.inProgress;
    case 'CLOSED':
    case 'RESOLVED':
    case 'COMPLETED':
      return CaseStatus.closed;
    case 'DELETED':
      return CaseStatus.deleted;
    default:
      return null;
  }
}

CaseStatus? _mapWorkflowStatusFromAccessType(String? accessType) {
  if (accessType == null || accessType.trim().isEmpty) return null;
  final normalized = accessType.trim().toUpperCase();
  if (normalized == 'INTERNAL' || normalized == 'EXTERNAL') return null;
  return _mapApiValueToNoteStatus(accessType);
}
