/// Supported phone countries for the login flow.
enum AuthPhoneCountry {
  usa(
    dialCode: '1',
    label: 'USA',
    flag: '🇺🇸',
    nationalLength: 10,
    hint: '(555) 000-0000',
  ),
  canada(
    dialCode: '1',
    label: 'Canada',
    flag: '🇨🇦',
    nationalLength: 10,
    hint: '(555) 000-0000',
  ),
  nepal(
    dialCode: '977',
    label: 'Nepal',
    flag: '🇳🇵',
    nationalLength: 10,
    hint: '98XXXXXXXX',
  );

  const AuthPhoneCountry({
    required this.dialCode,
    required this.label,
    required this.flag,
    required this.nationalLength,
    required this.hint,
  });

  final String dialCode;
  final String label;
  final String flag;
  final int nationalLength;
  final String hint;

  String get dialCodeDisplay => '+$dialCode';
}
