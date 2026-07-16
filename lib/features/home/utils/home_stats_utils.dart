import 'package:intl/intl.dart';

const _placeholder = '—';

String formatAgentStatCount(int? value) {
  if (value == null) return _placeholder;
  return value.toString();
}

String formatAgentStatMoney(String? value) {
  if (value == null) return _placeholder;

  final parsed = double.tryParse(value);
  if (parsed == null) return _placeholder;

  return NumberFormat.simpleCurrency(decimalDigits: 0).format(parsed);
}
