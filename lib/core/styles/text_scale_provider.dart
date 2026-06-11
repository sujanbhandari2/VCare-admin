import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/storage/storage_keys.dart';
import 'package:vcare_admin/core/services/storage/storage_service_provider.dart';

enum AppTextScale {
  small(0.9),
  normal(1.0),
  large(1.15);

  const AppTextScale(this.factor);

  final double factor;
}

final textScaleProvider = NotifierProvider<TextScaleNotifier, AppTextScale>(
  TextScaleNotifier.new,
);

class TextScaleNotifier extends Notifier<AppTextScale> {
  @override
  AppTextScale build() {
    final scaleName =
        ref
                .read(storageServiceProvider)
                .get(
                  StorageKeys.textScale,
                  defaultValue: AppTextScale.normal.name,
                )
            as String?;

    return AppTextScale.values.firstWhere(
      (value) => value.name == scaleName,
      orElse: () => AppTextScale.normal,
    );
  }

  Future<void> updateTextScale(AppTextScale scale) async {
    if (state == scale) return;

    await ref
        .read(storageServiceProvider)
        .set(StorageKeys.textScale, scale.name);
    state = scale;
  }
}
