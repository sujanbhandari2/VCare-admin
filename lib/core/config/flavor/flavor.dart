import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_template/shared/utils/extension_functions.dart';

enum Flavor {
  dev,
  qa,
  uat,
  prod;

  /// Method to get the flavor from the environment variable
  ///
  static Flavor get fromEnvironment {
    const flavor = appFlavor ?? 'prod';

    switch (flavor.toLowerCase()) {
      case 'dev':
      case 'development':
        return Flavor.dev;
      case 'qa':
        return Flavor.qa;
      case 'uat':
        return Flavor.uat;
      case 'prod':
      case 'production':
        return Flavor.prod;
      default:
        return Flavor.prod;
    }
  }

  /// Method to get localized app name as per flavor
  ///
  String localizedAppName(BuildContext context) {
    switch (this) {
      case Flavor.dev:
        return context.appLocalization.app_name_dev;
      case Flavor.qa:
        return context.appLocalization.app_name_qa;
      case Flavor.uat:
        return context.appLocalization.app_name_uat;
      case Flavor.prod:
        return context.appLocalization.app_name;
    }
  }
}
