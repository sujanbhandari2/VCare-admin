/// Validation + password requirements mirroring web `account.schema.ts`.
class AccountValidators {
  AccountValidators._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _lowerPattern = RegExp(r'[a-z]');
  static final _upperPattern = RegExp(r'[A-Z]');
  static final _numberPattern = RegExp(r'[0-9]');
  static final _specialPattern = RegExp(r'[^a-zA-Z0-9]');

  static final passwordRequirements = <AccountPasswordRequirement>[
    AccountPasswordRequirement(
      id: 'length',
      label: 'At least 8 characters',
      test: (password) => password.length >= 8,
    ),
    AccountPasswordRequirement(
      id: 'lowercase',
      label: 'One lowercase letter',
      test: (password) => _lowerPattern.hasMatch(password),
    ),
    AccountPasswordRequirement(
      id: 'uppercase',
      label: 'One uppercase letter',
      test: (password) => _upperPattern.hasMatch(password),
    ),
    AccountPasswordRequirement(
      id: 'number',
      label: 'One number',
      test: (password) => _numberPattern.hasMatch(password),
    ),
    AccountPasswordRequirement(
      id: 'special',
      label: 'One special character',
      test: (password) => _specialPattern.hasMatch(password),
    ),
  ];

  static String? validateFirstName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'First name is required';
    }
    if (trimmed.length > 50) {
      return 'First name is too long';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Last name is required';
    }
    if (trimmed.length > 50) {
      return 'Last name is too long';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final trimmed = value?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a valid email address';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateCurrentPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  static String? validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (password.length > 128) {
      return 'Password must be less than 128 characters';
    }
    if (!_lowerPattern.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!_upperPattern.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!_numberPattern.hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!_specialPattern.hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? validateConfirmPassword({
    required String? newPassword,
    required String? confirmPassword,
  }) {
    if ((confirmPassword ?? '').isEmpty) {
      return 'Please confirm your new password';
    }
    if (confirmPassword != newPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}

class AccountPasswordRequirement {
  const AccountPasswordRequirement({
    required this.id,
    required this.label,
    required this.test,
  });

  final String id;
  final String label;
  final bool Function(String password) test;
}
