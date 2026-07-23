import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';

/// Non-interactive USA country-code prefix for phone fields.
class LoginPhoneCountrySelector extends StatelessWidget {
  const LoginPhoneCountrySelector({super.key});

  static const AuthPhoneCountry country = AuthPhoneCountry.usa;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            country.dialCodeDisplay,
            style: TextStyle(
              color: vcare.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.only(left: 8),
            color: vcare.border,
          ),
        ],
      ),
    );
  }
}
