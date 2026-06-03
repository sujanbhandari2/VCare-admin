import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_template/features/onboarding/domain/enums/onboarding_item.dart';

part 'active_onboarding_item_provider.g.dart';

/// ActiveOnboardingItemNotifier
///
@Riverpod(keepAlive: true)
class ActiveOnboardingItemNotifier extends _$ActiveOnboardingItemNotifier {
  @override
  OnboardingItem build() => OnboardingItem.item1;

  /// Method to get the user profile
  ///
  void onActiveItemChanged(OnboardingItem item) {
    if (item != state) {
      state = item;
    }
  }
}
