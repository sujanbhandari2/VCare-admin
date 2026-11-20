import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Inline banner shown when the API returns `ACCOUNT_PASSWORD_LOCKED`.
///
/// Parity: web `LoginAccountLockedMessage`.
class LoginAccountLockedMessage extends StatefulWidget {
  const LoginAccountLockedMessage({super.key, required this.supportEmail});

  final String supportEmail;

  static const Color _background = Color(0xFFFEF2F2);
  static const Color _border = Color(0xFFFCA5A5);
  static const Color _text = Color(0xFFB91C1C);
  static const Color _email = Color(0xFF2563EB);

  @override
  State<LoginAccountLockedMessage> createState() =>
      _LoginAccountLockedMessageState();
}

class _LoginAccountLockedMessageState extends State<LoginAccountLockedMessage> {
  late final TapGestureRecognizer _emailRecognizer;

  @override
  void initState() {
    super.initState();
    _emailRecognizer = TapGestureRecognizer()..onTap = _openMailto;
  }

  @override
  void dispose() {
    _emailRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openMailto() async {
    final email = widget.supportEmail.trim();
    if (email.isEmpty) {
      return;
    }
    await launchUrlString(
      'mailto:$email',
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.supportEmail.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LoginAccountLockedMessage._background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoginAccountLockedMessage._border),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: LoginAccountLockedMessage._text,
          ),
          children: [
            const TextSpan(
              text:
                  'Your account has been blocked due to too many failed login attempts. Please contact ',
            ),
            TextSpan(
              text: email,
              style: const TextStyle(
                color: LoginAccountLockedMessage._email,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: LoginAccountLockedMessage._email,
              ),
              recognizer: _emailRecognizer,
            ),
            const TextSpan(text: ' for assistance.'),
          ],
        ),
      ),
    );
  }
}
