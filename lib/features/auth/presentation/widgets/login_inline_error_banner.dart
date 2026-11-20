import 'package:flutter/material.dart';

import 'package:vcare_admin/core/styles/vcare_theme.dart';

class LoginInlineErrorBanner extends StatelessWidget {
  const LoginInlineErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final vcare = context.vcare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vcare.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vcare.destructive.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: vcare.destructive,
        ),
      ),
    );
  }
}
