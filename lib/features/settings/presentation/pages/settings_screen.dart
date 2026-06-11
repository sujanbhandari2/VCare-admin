import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/app/router/app_router.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.appLocalization.settings),
        leading: const BackButton(
          style: ButtonStyle(iconSize: WidgetStatePropertyAll(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            tileColor: context.theme.colorScheme.surfaceContainerLow,
            leading: const Icon(Icons.language_outlined),
            title: Text(context.appLocalization.languages),
            subtitle: Text(
              context.appLocalization.settings_select_app_language,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              context.pushNamed(AppRouter.languages.toPathName);
            },
          ),
          const SizedBox(height: 12.0),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            tileColor: context.theme.colorScheme.surfaceContainerLow,
            leading: const Icon(Icons.palette_outlined),
            title: Text(
              context.appLocalization.settings_theme_and_color_scheme,
            ),
            subtitle: Text(
              context.appLocalization.settings_theme_and_seed_color,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              context.pushNamed(AppRouter.dynamicTheme.toPathName);
            },
          ),
        ],
      ),
    );
  }
}
