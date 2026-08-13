import 'package:intl/intl.dart';

/// Display helpers for account profile fields (web `formatRoleLabel` / dates).
class AccountFormatters {
  AccountFormatters._();

  static final _dateFormat = DateFormat.yMMMd();

  static String formatRoleLabel(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return '—';
    }

    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  static String formatAccountDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return '—';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return _dateFormat.format(parsed.toLocal());
  }

  static String emailVerifiedLabel(String? emailVerifiedAt) {
    final value = emailVerifiedAt?.trim() ?? '';
    if (value.isEmpty) {
      return 'Not verified';
    }
    return formatAccountDate(value);
  }

  static String displayName({
    required String? firstName,
    required String? lastName,
    required String? email,
  }) {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (full.isNotEmpty) {
      return full;
    }
    final mail = email?.trim() ?? '';
    return mail.isEmpty ? 'Account' : mail;
  }
}
