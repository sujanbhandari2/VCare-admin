import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/features/onboarding/domain/enums/onboarding_item.dart';
import 'package:flutter_template/features/onboarding/presentation/providers/active_onboarding_item_provider.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

class CarousalIndicator extends ConsumerWidget {
  final void Function(OnboardingItem item)? onClick;

  const CarousalIndicator({super.key, this.onClick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeOnboardingItemProvider);
    const height = 7.0;
    const width = 36.0;

    return Wrap(
      direction: Axis.horizontal,
      spacing: 4.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: OnboardingItem.values.map((item) {
        return GestureDetector(
          onTap: () {
            onClick?.call(item);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 275),
            width: item == active ? width : height,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              color: item == active
                  ? context.theme.primaryColor
                  : context.theme.primaryColorLight,
            ),
          ),
        );
      }).toList(),
    );
  }
}
