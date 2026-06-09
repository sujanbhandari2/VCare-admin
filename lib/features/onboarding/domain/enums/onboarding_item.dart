import 'package:flutter/material.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

enum OnboardingItem {
  item1(
    title: "Onboarding Item1",
    description: "This is the description of the on boarding item 1",
    assetsImage: "assets/images/onboarding/item1.png",
  ),
  item2(
    title: "Onboarding Item2",
    description: "This is the description of the on boarding item 2",
    assetsImage: "assets/images/onboarding/item2.png",
  ),
  item3(
    title: "Onboarding Item3",
    description: "This is the description of the on boarding item 3",
    assetsImage: "assets/images/onboarding/item3.png",
  ),
  item4(
    title: "Onboarding Item4",
    description: "This is the description of the on boarding item 4",
    assetsImage: "assets/images/onboarding/item4.png",
    isEnd: true,
  );

  final String title;
  final String description;
  final String? assetsImage;
  final bool isEnd;

  const OnboardingItem({
    required this.title,
    required this.description,
    this.assetsImage,
    this.isEnd = false,
  });

  /// Method to get the localized title
  /// [context] context of the widget
  ///
  String localizedTitle(BuildContext context) {
    return this == item1
        ? context.appLocalization.item1
        : this == item2
        ? context.appLocalization.item2
        : this == item3
        ? context.appLocalization.item3
        : context.appLocalization.item4;
  }

  /// Method to get the localized description
  /// [context] context of the widget
  ///
  String localizedDescription(BuildContext context) {
    return this == item1
        ? context.appLocalization.item1_description
        : this == item2
        ? context.appLocalization.item2_description
        : this == item3
        ? context.appLocalization.item3_description
        : context.appLocalization.item4_description;
  }
}
