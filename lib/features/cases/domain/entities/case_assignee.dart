/// Team member that can be assigned to a case or mentioned in notes.
class CaseAssignee {
  const CaseAssignee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.role = '',
    this.displayName,
    this.profileImage,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? displayName;
  final String? profileImage;

  String get fullName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    final parts = [firstName.trim(), lastName.trim()].where((p) => p.isNotEmpty);
    if (parts.isEmpty) return email.isNotEmpty ? email : 'Unknown';
    return parts.join(' ');
  }

  String get initials {
    final first = firstName.trim().isNotEmpty
        ? firstName.trim()[0].toUpperCase()
        : '';
    final last = lastName.trim().isNotEmpty
        ? lastName.trim()[0].toUpperCase()
        : '';
    final value = '$first$last';
    return value.isEmpty ? '?' : value;
  }
}
