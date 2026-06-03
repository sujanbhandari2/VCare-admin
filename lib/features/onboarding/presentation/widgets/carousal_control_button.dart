import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/shared/widgets/app_button.dart';

import 'package:flutter_template/features/onboarding/domain/enums/onboarding_item.dart';
import 'package:flutter_template/features/onboarding/presentation/providers/active_onboarding_item_provider.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

class CarousalControlButton extends ConsumerWidget {
  final void Function(OnboardingItem item)? onClick;

  const CarousalControlButton({super.key, this.onClick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeOnboardingItemProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AppButton.elevated(
        text: active.isEnd
            ? context.appLocalization.get_started
            : context.appLocalization.next,
        icon: !active.isEnd ? Icons.arrow_right_alt : null,
        iconAlignment: .end,
        onPressed: () {
          onClick?.call(active);
        },
      ),
    );
  }
}
