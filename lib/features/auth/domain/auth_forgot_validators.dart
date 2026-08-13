/// Password strength validation — parity with web auth/utils/password.ts
class AuthPasswordValidator {
  AuthPasswordValidator._();

  static String? validateStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include a lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include a number.';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Password must include a special character.';
    }
    return null;
  }
}

/// DOB validation — parity with web auth/utils/dob.ts
class AuthForgotDobValidator {
  AuthForgotDobValidator._();

  static String? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter your date of birth.';
    }

    final date = _parseIsoDate(trimmed);
    if (date == null) {
      return 'Enter a valid date of birth.';
    }

    final today = _parseIsoDate(_todayIsoLocal());
    if (today != null && date.isAfter(today)) {
      return 'Date of birth cannot be in the future.';
    }

    return null;
  }

  static DateTime? _parseIsoDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  static String _todayIsoLocal() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

/// ZIP validation — parity with web auth/utils/zipCode.ts
class AuthForgotZipValidator {
  AuthForgotZipValidator._();

  static String? validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter your ZIP code.';
    }

    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(trimmed)) {
      return 'Enter a valid 5-digit ZIP code.';
    }

    return null;
  }
}
