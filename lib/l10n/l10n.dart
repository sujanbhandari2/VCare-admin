import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';

class L10n {
  static const Locale en = Locale('en', 'US'); // American English
  static const Locale ne = Locale('ne', 'NP'); // Nepali
  static const Locale bn = Locale('bn', 'BD'); // Bengali

  static final all = [en, ne, bn];

  static Locale fromLanguageCode(String code) {
    if (code == ne.languageCode) return ne;
    if (code == bn.languageCode) return bn;
    return en;
  }
}

/// Locale Provider
///
final localeStateProvider = NotifierProvider<LocaleStateNotifier, Locale>(
  LocaleStateNotifier.new,
);

/// Locale State Notifier Class
///
class LocaleStateNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final lCode = ref
        .read(storageServiceProvider)
        .get(StorageKeys.locale, defaultValue: L10n.en.languageCode);

    return L10n.fromLanguageCode(lCode ?? L10n.en.languageCode);
  }

  /// Change/Update locale
  ///
  Future<void> changeLocale(Locale? locale) async {
    final storageService = ref.read(storageServiceProvider);

    final newLocale = L10n.fromLanguageCode((locale ?? L10n.en).languageCode);

    if (state.languageCode != newLocale.languageCode) {
      await storageService.set(StorageKeys.locale, newLocale.languageCode);
      state = newLocale;
    }
  }
}
