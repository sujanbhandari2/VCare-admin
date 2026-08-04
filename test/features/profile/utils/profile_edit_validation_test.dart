import 'package:flutter_test/flutter_test.dart';

import 'package:vcare_admin/features/profile/utils/profile_edit_validation.dart';

void main() {
  ProfileEditFormData validForm({
    String firstName = 'Jane',
    String middleName = '',
    String lastName = 'Doe',
    String email = 'jane@example.com',
    String phone = '5551234567',
    String dob = '1990-05-14',
    String gender = '',
    String line1 = '',
    String city = '',
    String state = '',
    String postalCode = '',
    String primaryCity = '',
    String primaryState = '',
    String bio = '',
  }) {
    return ProfileEditFormData(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      dob: dob,
      gender: gender,
      line1: line1,
      city: city,
      state: state,
      postalCode: postalCode,
      primaryCity: primaryCity,
      primaryState: primaryState,
      bio: bio,
    );
  }

  group('ProfileEditValidation', () {
    test('photo limit is 25MB', () {
      expect(ProfileEditValidation.maxProfilePhotoBytes, 25 * 1024 * 1024);
      expect(ProfileEditValidation.maxProfilePhotoLabel, '25MB');
    });

    test('requires first and last name', () {
      final errors = ProfileEditValidation.validate(
        validForm(firstName: '', lastName: ''),
      );

      expect(errors['firstName'], 'First name is required');
      expect(errors['lastName'], 'Last name is required');
    });

    test('allows empty date of birth', () {
      final errors = ProfileEditValidation.validate(validForm(dob: ''));
      expect(errors.containsKey('dob'), isFalse);
    });

    test('allows empty gender', () {
      final errors = ProfileEditValidation.validate(validForm(gender: ''));
      expect(errors.containsKey('gender'), isFalse);
    });

    test('allows valid gender options', () {
      for (final gender in ['Male', 'Female', 'Others']) {
        final errors = ProfileEditValidation.validate(validForm(gender: gender));
        expect(errors.containsKey('gender'), isFalse, reason: gender);
      }
    });

    test('rejects invalid gender', () {
      final errors = ProfileEditValidation.validate(
        validForm(gender: 'Non-binary'),
      );
      expect(errors['gender'], 'Select a gender');
    });

    test('allows empty address', () {
      final errors = ProfileEditValidation.validate(validForm());
      expect(errors.containsKey('line1'), isFalse);
      expect(errors.containsKey('city'), isFalse);
    });

    test('rejects partial address', () {
      final errors = ProfileEditValidation.validate(
        validForm(line1: '123 Market St', city: 'SF'),
      );

      expect(
        errors['line1'],
        'Complete all address fields or leave them blank.',
      );
    });

    test('allows complete address', () {
      final errors = ProfileEditValidation.validate(
        validForm(
          line1: '123 Market St',
          city: 'San Francisco',
          state: 'CA',
          postalCode: '94103',
        ),
      );

      expect(errors.containsKey('line1'), isFalse);
    });

    test('rejects partial primary location', () {
      final errors = ProfileEditValidation.validate(
        validForm(primaryCity: 'Tampa'),
      );

      expect(
        errors['primaryCity'],
        'Enter both city and state for primary location, or leave it blank.',
      );
    });

    test('allows complete primary location', () {
      final errors = ProfileEditValidation.validate(
        validForm(primaryCity: 'Tampa', primaryState: 'FL'),
      );

      expect(errors.containsKey('primaryCity'), isFalse);
    });

    test('enforces bio max length', () {
      final errors = ProfileEditValidation.validate(
        validForm(bio: 'x' * 501),
      );

      expect(errors['bio'], 'Bio must be under 500 characters');
    });
  });
}
