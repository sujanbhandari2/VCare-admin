class CaseNoteAuthorModel {
  const CaseNoteAuthorModel({
    this.id,
    this.name,
    this.profilePreviewLink,
  });

  final String? id;
  final String? name;
  final String? profilePreviewLink;

  /// Parses author as string id or `{id, name, profilePreviewLink}`.
  static CaseNoteAuthorModel? parse(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return CaseNoteAuthorModel(id: trimmed);
    }

    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      return CaseNoteAuthorModel(
        id: _optionalString(json['id']),
        name: _optionalString(json['name']),
        profilePreviewLink: _optionalString(json['profilePreviewLink']),
      );
    }

    return null;
  }
}

class CaseNoteFileModel {
  const CaseNoteFileModel({
    required this.id,
    required this.name,
    required this.url,
    this.note,
  });

  final String id;
  final String name;
  final String url;
  final String? note;

  factory CaseNoteFileModel.fromJson(Map<String, dynamic> json) {
    return CaseNoteFileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      note: _optionalString(json['note']),
    );
  }
}

class CaseNoteTagModel {
  const CaseNoteTagModel({
    this.taggedUserId,
    required this.taggedEmail,
    required this.taggedName,
  });

  final String? taggedUserId;
  final String taggedEmail;
  final String taggedName;

  factory CaseNoteTagModel.fromJson(Map<String, dynamic> json) {
    return CaseNoteTagModel(
      taggedUserId: _optionalString(json['taggedUserId']),
      taggedEmail: json['taggedEmail']?.toString() ?? '',
      taggedName: json['taggedName']?.toString() ?? '',
    );
  }
}

/// API shape for `ApiCaseNoteDetail`.
class CaseNoteModel {
  const CaseNoteModel({
    required this.id,
    required this.note,
    this.status,
    this.accessType,
    this.tags = const [],
    this.files = const [],
    this.externalInviteId,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String note;
  final String? status;
  final String? accessType;
  final List<CaseNoteTagModel> tags;
  final List<CaseNoteFileModel> files;
  final String? externalInviteId;
  final CaseNoteAuthorModel? createdBy;
  final String? createdAt;

  factory CaseNoteModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final filesRaw = json['files'];

    return CaseNoteModel(
      id: json['id']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      status: _optionalString(json['status']),
      accessType: _optionalString(json['accessType']),
      tags: tagsRaw is List
          ? tagsRaw
                .whereType<Map>()
                .map(
                  (item) => CaseNoteTagModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      files: filesRaw is List
          ? filesRaw
                .whereType<Map>()
                .map(
                  (item) => CaseNoteFileModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      externalInviteId: _optionalString(json['externalInviteId']),
      createdBy: CaseNoteAuthorModel.parse(json['createdBy']),
      createdAt: _optionalString(json['createdAt']),
    );
  }

  static bool isValidApiData(dynamic data) {
    return data is Map && data['id'] != null;
  }
}

/// User available for @mentions (`ApiCaseNoteTagUser`).
class CaseNoteTagUserModel {
  const CaseNoteTagUserModel({
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

  factory CaseNoteTagUserModel.fromJson(Map<String, dynamic> json) {
    return CaseNoteTagUserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: _optionalString(json['firstName']),
      lastName: _optionalString(json['lastName']),
      profileImage: _optionalString(json['profileImage']),
      role: _optionalString(json['role']),
    );
  }
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}
