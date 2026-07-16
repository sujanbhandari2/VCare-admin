import 'package:flutter/widgets.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Validates national phone numbers for supported login countries.
class AuthPhoneValidator {
  AuthPhoneValidator._();

  static String? validate(
    String? value, {
    required AuthPhoneCountry country,
    required BuildContext context,
  }) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    final l10n = context.appLocalization;

    if (digits.isEmpty) {
      return l10n.validate_mobile_required;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
      return l10n.validate_mobile_invalid_digits;
    }

    if (digits.length != country.nationalLength) {
      return l10n.validate_mobile_invalid_length;
    }

    return switch (country) {
      AuthPhoneCountry.usa || AuthPhoneCountry.canada => null,
      AuthPhoneCountry.nepal =>
        RegExp(r'^(97|98)\d{8}$').hasMatch(digits)
            ? null
            : 'Enter a valid 10-digit Nepal mobile number.',
    };
  }
}
