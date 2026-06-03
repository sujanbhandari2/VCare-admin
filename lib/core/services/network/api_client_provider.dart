import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/core/services/storage/storage_service_provider.dart';
import 'package:flutter_template/core/config/flavor/configuration_provider.dart';
import 'package:flutter_template/core/services/network/dio_api_client.dart';
import 'package:flutter_template/core/services/network/api_client.dart';

/// Provider that maps an [ApiClient] interface to implementation
final apiClientProvider = Provider<ApiClient>((ref) {
  final configuration = ref.watch(flavorConfigurationProvider);
  final storageService = ref.watch(storageServiceProvider);

  return DioApiClient(configuration, storageService);
});
