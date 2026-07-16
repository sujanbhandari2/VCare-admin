/// Form fields for profile edit, matching vcareapp ProfileEditForm.
class ProfileEditFormData {
  const ProfileEditFormData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dob,
    this.line1 = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'United States',
  });

  final String fullName;
  final String email;
  final String phone;
  final String dob;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  ProfileEditFormData copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? dob,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return ProfileEditFormData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
    );
  }
}

/// Validation parity with vcareapp profileEditSchema.
class ProfileEditValidation {
  ProfileEditValidation._();

  static const maxProfilePhotoBytes = 25 * 1024 * 1024;

  static String get maxProfilePhotoLabel =>
      '${maxProfilePhotoBytes ~/ (1024 * 1024)}MB';

  static Map<String, String> validate(
    ProfileEditFormData form, {
    bool validatePersonalInfo = true,
    bool validatePhone = true,
  }) {
    final errors = <String, String>{};

    if (validatePersonalInfo) {
      final fullName = form.fullName.trim();
      if (fullName.isEmpty) {
        errors['fullName'] = 'Name is required';
      } else if (fullName.length > 80) {
        errors['fullName'] = 'Name must be under 80 characters';
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
        } else if (phone.length > 20) {
          errors['phone'] = 'Phone must be under 20 characters';
        }
      }

      if (form.dob.trim().isEmpty) {
        errors['dob'] = 'Date of birth is required';
      }
    }

    final line1 = form.line1.trim();
    if (line1.isEmpty) {
      errors['line1'] = 'Street address is required';
    } else if (line1.length > 120) {
      errors['line1'] = 'Street address must be under 120 characters';
    }

    if (form.line2.trim().length > 120) {
      errors['line2'] = 'Apt / suite must be under 120 characters';
    }

    final city = form.city.trim();
    if (city.isEmpty) {
      errors['city'] = 'City is required';
    } else if (city.length > 80) {
      errors['city'] = 'City must be under 80 characters';
    }

    final state = form.state.trim();
    if (state.isEmpty) {
      errors['state'] = 'State is required';
    } else if (state.length > 60) {
      errors['state'] = 'State must be under 60 characters';
    }

    final postalCode = form.postalCode.trim();
    if (postalCode.isEmpty) {
      errors['postalCode'] = 'Postal code is required';
    } else if (postalCode.length > 12) {
      errors['postalCode'] = 'Postal code must be under 12 characters';
    }

    final country = form.country.trim();
    if (country.isEmpty) {
      errors['country'] = 'Country is required';
    } else if (country.length > 60) {
      errors['country'] = 'Country must be under 60 characters';
    }

    return errors;
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
