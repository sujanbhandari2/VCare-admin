import 'package:vcare_admin/features/profile/utils/family_member_edit_utils.dart';
import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

class FamilyMemberFormData {
  const FamilyMemberFormData({
    required this.name,
    required this.relationship,
    required this.gender,
    required this.dob,
  });

  final String name;
  final String relationship;
  final String gender;
  final String dob;
}

abstract final class FamilyMemberEditValidation {
  static Map<String, String> validate(FamilyMemberFormData form) {
    final errors = <String, String>{};
    final name = form.name.trim();

    if (name.isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.length > 80) {
      errors['name'] = 'Name must be under 80 characters';
    }

    if (!relationshipOptions.contains(form.relationship)) {
      errors['relationship'] = 'Select a relationship';
    }

    if (!genderOptions.contains(form.gender)) {
      errors['gender'] = 'Select a gender';
    }

    if (form.dob.isEmpty) {
      errors['dob'] = 'Date of birth is required';
    } else {
      final parsed = parseProfileDob(form.dob);
      if (parsed == null || parsed.isAfter(DateTime.now())) {
        errors['dob'] = 'Enter a valid past date';
      }
    }

    return errors;
  }
}
