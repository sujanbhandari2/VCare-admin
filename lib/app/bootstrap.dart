import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/firebase/firebase_service.dart';

import '../core/config/env/env.dart';
import '../core/config/flavor/configuration.dart';
import '../core/config/flavor/configuration_provider.dart';
import '../core/config/flavor/flavor.dart';
import '../core/services/storage/hive_storage_service.dart';
import '../core/services/storage/storage_service_provider.dart';
import 'app.dart';

Future<void> bootstrap() async {
  // Ensuring widgets flutter binding initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment variables
  await Env.instance.load();

  // Set preferred orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Flavor configuration
  final configuration = Configuration.of(Flavor.fromEnvironment);

  // Hive-specific initialization
  final storageService = HiveStorageService.instance;
  await storageService.init(configuration.hiveBoxName);

  // Initialize Firebase
  await FirebaseService.initializeFirebase();

  // Run app
  runApp(
    ConfigurationProvider(
      configuration: configuration,
      child: ProviderScope(
        overrides: [
          flavorConfigurationProvider.overrideWithValue(configuration),
          storageServiceProvider.overrideWithValue(storageService),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
