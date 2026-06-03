import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Env for handling environment variables
///
class Env {
  /// Private internal constructor
  ///
  Env._internal() : _variables = <String, String>{};

  /// Private instance of instance
  ///
  static Env? _instance;

  /// Lazy-loaded singleton instance of this class
  ///
  static Env get instance {
    _instance ??= ._internal();
    return _instance!;
  }

  /// Singleton instance of this class
  ///
  // static final Env instance = ._internal();

  /// Variables that store key value pairs
  ///
  final Map<String, String> _variables;

  /// Method to get all keys
  ///
  Set<String> get keys => _variables.keys.toSet();

  /// Method to get all variables (read-only)
  ///
  Map<String, String> get variables => .unmodifiable(_variables);

  /// Method to check if a key exists
  /// [key] - Key to check
  ///
  bool containsKey(String key) => _variables.containsKey(key);

  /// Method to get value by key
  /// [key] - Key specified in .env file
  /// [defaultValue] - Default fallback value if not found in env
  ///
  String? valueOf(String key, {String? defaultValue}) =>
      _variables[key] ?? defaultValue;

  /// Method to get boolean value
  /// [key] - Key specified in .env file
  /// [defaultValue] - Default fallback value if not found in env
  ///
  bool boolOf(String key, {bool defaultValue = false}) {
    final value = _variables[key]?.toLowerCase();
    if (value == null) return defaultValue;
    return value == 'true' || value == '1' || value == 'yes' || value == 'on';
  }

  /// Method to get integer value
  /// [key] - Key specified in .env file
  /// [defaultValue] - Default fallback value if not found in env
  ///
  int intOf(String key, {int? defaultValue}) {
    final value = _variables[key];
    if (value == null) return defaultValue ?? 0;
    return .tryParse(value) ?? defaultValue ?? 0;
  }

  /// Method to get double value
  /// [key] - Key specified in .env file
  /// [defaultValue] - Default fallback value if not found in env
  ///
  double doubleOf(String key, {double? defaultValue}) {
    final value = _variables[key];
    if (value == null) return defaultValue ?? 0.0;
    return .tryParse(value) ?? defaultValue ?? 0.0;
  }

  /// Method to get list value (comma-separated)
  /// [key] - Key specified in .env file
  /// [defaultValue] - Default fallback value if not found in env
  ///
  List<String> listOf(String key, {List<String>? defaultValue}) {
    final value = _variables[key];
    if (value == null || value.isEmpty) return defaultValue ?? [];
    return value.split(',').map((e) => e.trim()).toList();
  }

  /// Method to load .env file from the
  ///
  Future<void> load() async {
    try {
      // Getting file contents from the file .env
      final fileContent = await rootBundle.loadString('.env');

      // Parsing file contents and getting key value pairs
      final variables = _parse(fileContent);

      // clearing _variables to make it empty
      _variables.clear();

      // Adding variables to the _variables
      _variables.addAll(variables);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Function to parse .env file and return a dictionary
  ///
  Map<String, String> _parse(String fileContent) {
    // Split the file content into lines
    final lines = fileContent.split('\n');

    // Create a Map to store the key-value pairs
    final pairs = <String, String>{};

    // Iterate over each line to extract key-value pairs
    for (var line in lines) {
      // Remove unnecessary whitespaces
      line = line.trim();

      // Ignore comments (starting with #) and empty lines
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = line.substring(0, separatorIndex).trim();
      if (key.isEmpty) continue;

      var value = line.substring(separatorIndex + 1).trim();
      final commentIndex = value.indexOf('#');
      if (commentIndex >= 0) {
        value = value.substring(0, commentIndex).trim();
      }

      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }

      pairs[key] = value;
    }

    return pairs;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Env &&
          runtimeType == other.runtimeType &&
          hashCode == other.hashCode;

  @override
  int get hashCode => _variables.hashCode;
}
