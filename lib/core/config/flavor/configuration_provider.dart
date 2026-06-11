import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vcare_admin/core/config/flavor/configuration.dart';

class ConfigurationProvider extends InheritedWidget {
  final Configuration configuration;

  const ConfigurationProvider({
    super.key,
    required this.configuration,
    required super.child,
  });

  static ConfigurationProvider of(BuildContext context) {
    final ConfigurationProvider? result = context
        .dependOnInheritedWidgetOfExactType<ConfigurationProvider>();
    assert(
      result != null,
      'No ConfigurationProvider found in the widget tree.',
    );
    return result!;
  }

  static ConfigurationProvider? maybeOf(BuildContext context) {
    final ConfigurationProvider? result = context
        .dependOnInheritedWidgetOfExactType<ConfigurationProvider>();
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ConfigurationProvider oldWidget) {
    throw configuration != oldWidget.configuration;
  }
}

/// Provider that provides instance of [Configuration]
///
final flavorConfigurationProvider = Provider<Configuration>((_) => .of());
