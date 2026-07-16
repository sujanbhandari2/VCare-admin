import 'package:flutter/services.dart';

import 'package:vcare_admin/features/auth/domain/auth_phone_formatter.dart';
import 'package:vcare_admin/features/auth/domain/entities/auth_phone_country.dart';

/// Formats phone input as the user types according to [country].
class AuthNationalPhoneInputFormatter extends TextInputFormatter {
  AuthNationalPhoneInputFormatter(this.country);

  final AuthPhoneCountry country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (newDigits.length > country.nationalLength) {
      return oldValue;
    }

    final formatted = AuthPhoneFormatter.formatNationalDisplay(
      newDigits,
      country,
    );
    final digitOffset = _digitOffsetBeforeCursor(
      newValue.text,
      newValue.selection.baseOffset,
    );
    final selectionOffset = _selectionOffsetForDigitIndex(
      formatted,
      digitOffset.clamp(0, newDigits.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  int _digitOffsetBeforeCursor(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    return text.substring(0, safeCursor).replaceAll(RegExp(r'\D'), '').length;
  }

  int _selectionOffsetForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) {
      return 0;
    }

    var digitsSeen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        digitsSeen++;
        if (digitsSeen == digitIndex) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
