import 'package:vcare_admin/features/profile/utils/profile_utils.dart';

/// Form fields for profile edit, matching web ProfileEditForm.
class ProfileEditFormData {
  const ProfileEditFormData({
    required this.firstName,
    this.middleName = '',
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dob,
    this.gender = '',
    this.allowTextNotification = false,
    this.line1 = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'United States',
    this.primaryCity = '',
    this.primaryState = '',
    this.bio = '',
  });

  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String dob;
  final String gender;
  final bool allowTextNotification;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String primaryCity;
  final String primaryState;
  final String bio;

  ProfileEditFormData copyWith({
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? dob,
    String? gender,
    bool? allowTextNotification,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? primaryCity,
    String? primaryState,
    String? bio,
  }) {
    return ProfileEditFormData(
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      allowTextNotification:
          allowTextNotification ?? this.allowTextNotification,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      primaryCity: primaryCity ?? this.primaryCity,
      primaryState: primaryState ?? this.primaryState,
      bio: bio ?? this.bio,
    );
  }
}

/// Validation parity with web profileEditSchema + submit custom rules.
class ProfileEditValidation {
  ProfileEditValidation._();

  static const maxProfilePhotoBytes = 25 * 1024 * 1024;
  static const maxBioLength = 500;

  static String get maxProfilePhotoLabel =>
      '${maxProfilePhotoBytes ~/ (1024 * 1024)}MB';

  static Map<String, String> validate(
    ProfileEditFormData form, {
    bool validatePersonalInfo = true,
    bool validatePhone = true,
  }) {
    final errors = <String, String>{};

    if (validatePersonalInfo) {
      final firstName = form.firstName.trim();
      if (firstName.isEmpty) {
        errors['firstName'] = 'First name is required';
      } else if (firstName.length > 50) {
        errors['firstName'] = 'First name must be under 50 characters';
      }

      final middleName = form.middleName.trim();
      if (middleName.length > 50) {
        errors['middleName'] = 'Middle name must be under 50 characters';
      }

      final lastName = form.lastName.trim();
      if (lastName.isEmpty) {
        errors['lastName'] = 'Last name is required';
      } else if (lastName.length > 50) {
        errors['lastName'] = 'Last name must be under 50 characters';
      }

      final email = form.email.trim();
      if (email.isEmpty || !_isValidEmail(email)) {
        errors['email'] = 'Invalid email';
      } else if (email.length > 255) {
        errors['email'] = 'Email must be under 255 characters';
      }

      if (validatePhone) {
        final phone = form.phone.trim();
        if (phone.length < 7) {
          errors['phone'] = 'Enter a valid phone';
        } else if (phone.length > 10) {
          errors['phone'] = 'Phone must be under 10 characters';
        }
      }

      final gender = form.gender.trim();
      if (gender.isNotEmpty && !profileGenderOptions.contains(gender)) {
        errors['gender'] = 'Select a gender';
      }

      if (form.bio.trim().length > maxBioLength) {
        errors['bio'] = 'Bio must be under $maxBioLength characters';
      }
    }

    final line1 = form.line1.trim();
    final line2 = form.line2.trim();
    final city = form.city.trim();
    final state = form.state.trim();
    final postalCode = form.postalCode.trim();

    if (line1.length > 120) {
      errors['line1'] = 'Street address must be under 120 characters';
    }
    if (line2.length > 120) {
      errors['line2'] = 'Apt / suite must be under 120 characters';
    }
    if (city.length > 80) {
      errors['city'] = 'City must be under 80 characters';
    }
    if (state.length > 60) {
      errors['state'] = 'State must be under 60 characters';
    }
    if (postalCode.length > 12) {
      errors['postalCode'] = 'Postal code must be under 12 characters';
    }

    final hasAddress = line1.isNotEmpty &&
        city.isNotEmpty &&
        state.isNotEmpty &&
        postalCode.isNotEmpty;
    final partialAddress = line1.isNotEmpty ||
        city.isNotEmpty ||
        state.isNotEmpty ||
        postalCode.isNotEmpty;
    if (partialAddress && !hasAddress) {
      errors['line1'] = 'Complete all address fields or leave them blank.';
    }

    final primaryCity = form.primaryCity.trim();
    final primaryState = form.primaryState.trim();
    if (primaryCity.length > 100) {
      errors['primaryCity'] = 'Primary city must be under 100 characters';
    }
    if (primaryState.length > 100) {
      errors['primaryState'] = 'Primary state must be under 100 characters';
    }
    final hasPrimary = primaryCity.isNotEmpty && primaryState.isNotEmpty;
    final partialPrimary = primaryCity.isNotEmpty || primaryState.isNotEmpty;
    if (partialPrimary && !hasPrimary) {
      errors['primaryCity'] =
          'Enter both city and state for primary location, or leave it blank.';
    }

    return errors;
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
