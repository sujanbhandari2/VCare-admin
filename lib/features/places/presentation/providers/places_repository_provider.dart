import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/core/services/network/api_client_provider.dart';
import 'package:vcare_admin/features/places/data/repositories/places_repository_impl.dart';
import 'package:vcare_admin/features/places/domain/repositories/places_repository.dart';

part 'places_repository_provider.g.dart';

@Riverpod(keepAlive: true)
PlacesRepository placesRepository(Ref ref) {
  final apiClient = ref.read(apiClientProvider);
  return PlacesRepositoryImpl(apiClient);
}
