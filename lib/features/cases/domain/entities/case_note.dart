import 'package:vcare_admin/features/cases/domain/entities/referral_case.dart';

/// A note on a referral case.
class CaseNote {
  const CaseNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.authorName = '',
    this.authorInitials = '',
    this.status,
    this.accessType,
    this.createdById,
    this.authorProfilePreviewLink,
    this.files = const [],
    this.tags = const [],
    this.externalInviteId,
    this.canEdit = false,
    this.canDelete = false,
  });

  final String id;
  final String authorName;
  final String authorInitials;
  final String content;
  final String createdAt;
  final CaseStatus? status;
  final String? accessType;
  final String? createdById;
  final String? authorProfilePreviewLink;
  final List<CaseNoteFile> files;
  final List<CaseNoteTag> tags;
  final String? externalInviteId;
  final bool canEdit;
  final bool canDelete;

  bool get isPublic {
    final value = accessType?.trim().toUpperCase();
    return value == 'EXTERNAL' || value == 'PUBLIC';
  }

  CaseNote copyWith({
    String? id,
    String? authorName,
    String? authorInitials,
    String? content,
    String? createdAt,
    CaseStatus? status,
    String? accessType,
    String? createdById,
    String? authorProfilePreviewLink,
    List<CaseNoteFile>? files,
    List<CaseNoteTag>? tags,
    String? externalInviteId,
    bool? canEdit,
    bool? canDelete,
  }) {
    return CaseNote(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorInitials: authorInitials ?? this.authorInitials,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      accessType: accessType ?? this.accessType,
      createdById: createdById ?? this.createdById,
      authorProfilePreviewLink:
          authorProfilePreviewLink ?? this.authorProfilePreviewLink,
      files: files ?? this.files,
      tags: tags ?? this.tags,
      externalInviteId: externalInviteId ?? this.externalInviteId,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}

class CaseNoteFile {
  const CaseNoteFile({
    required this.id,
    required this.name,
    required this.url,
    this.note,
  });

  final String id;
  final String name;
  final String url;
  final String? note;
}

class CaseNoteTag {
  const CaseNoteTag({
    required this.taggedEmail,
    required this.taggedName,
    this.taggedUserId,
  });

  final String? taggedUserId;
  final String taggedEmail;
  final String taggedName;
}

class CaseNotePublicUrl {
  const CaseNotePublicUrl({required this.url, required this.name});

  final String url;
  final String name;
}

/// User available for @mentions on case notes.
class CaseNoteTagUser {
  const CaseNoteTagUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.role,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String? role;

  String get displayName {
    final parts = [
      firstName?.trim() ?? '',
      lastName?.trim() ?? '',
    ].where((p) => p.isNotEmpty);
    if (parts.isEmpty) return email;
    return parts.join(' ');
  }
}
