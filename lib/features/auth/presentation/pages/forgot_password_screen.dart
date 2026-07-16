import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

/// Legacy route — redirects to in-login forgot flow (web parity).
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.goNamed(AppRouter.login.toPathName);
    });
    return const Scaffold(body: SizedBox.shrink());
  }
}
