import 'package:flutter/material.dart';
import 'package:vcare_admin/features/auth/domain/enums/base_enum.dart';
import 'package:vcare_admin/shared/utils/extension_functions.dart';

enum Gender implements BaseEnum {
  male('Male'),
  female('Female'),
  other('Other');

  final String label;

  const Gender(this.label);

  /// Method to get gender form the string
  ///
  static Gender fromStr(String? s) {
    if (s?.toLowerCase() == male.name) return male;
    if (s?.toLowerCase() == female.name) return female;
    return other;
  }

  /// Method to get localize label
  ///
  @override
  String localizedLabel(BuildContext context) {
    return this == male
        ? context.appLocalization.gender_male
        : this == female
        ? context.appLocalization.gender_female
        : context.appLocalization.gender_other;
  }
}
