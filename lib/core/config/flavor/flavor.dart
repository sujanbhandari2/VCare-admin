import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

enum Flavor {
  dev,
  staging,
  production;

  /// Method to get the flavor from the environment variable
  ///
  static Flavor get fromEnvironment {
    const flavor = appFlavor ?? 'prod';

    return flavor.toLowerCase() == 'dev' || flavor.toString() == 'development'
        ? dev
        : flavor.toLowerCase() == 'staging'
            ? staging
            : production;
  }

  /// Method to get localized app name as per flavor
  ///
  String localizedAppName(BuildContext context) => this == dev
      ? context.appLocalization.app_name_dev
      : this == staging
          ? context.appLocalization.app_name_staging
          : context.appLocalization.app_name;
}
