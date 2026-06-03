import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/l10n/l10n.dart';
import 'package:flutter_template/shared/widgets/gap.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

class LanguagesSettingsScreen extends ConsumerWidget {
  const LanguagesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.appLocalization.languages),
        leading: const BackButton(
          style: ButtonStyle(iconSize: WidgetStatePropertyAll(20)),
        ),
      ),
      body: ListView.separated(
        itemCount: L10n.all.length,
        padding: const .symmetric(vertical: 20.0),
        itemBuilder: (BuildContext context, int index) {
          final l = L10n.all[index];

          return Padding(
            padding: const .symmetric(horizontal: 20.0),
            child: InkWell(
              onTap: () {
                ref.read(localeStateProvider.notifier).changeLocale(l);
              },
              borderRadius: .circular(12.0),
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 175),
                padding: const .symmetric(horizontal: 16.0, vertical: 16.0),
                decoration: BoxDecoration(
                  borderRadius: .circular(12.0),
                  border: Border.all(
                    color: l.languageCode == locale.languageCode
                        ? context.theme.colorScheme.primary
                        : context.theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      l.flag,
                      style: context.textTheme.titleLarge?.copyWith(
                        height: 0.75,
                      ),
                    ),
                    const Gap(12.0),
                    Text(
                      l.unlocalizedLabel,
                      style: context.textTheme.labelLarge,
                    ),
                    const Spacer(),
                    Text(
                      "(${l.translatedLabel})",
                      style: context.textTheme.labelMedium?.copyWith(
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Gap(12.0);
        },
      ),
    );
  }
}
