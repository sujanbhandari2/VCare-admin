import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vcare_admin/features/find_care/data/repositories/find_care_location_repository_impl.dart';
import 'package:vcare_admin/features/find_care/domain/repositories/find_care_location_repository.dart';

part 'find_care_location_repository_provider.g.dart';

@Riverpod(keepAlive: true)
FindCareLocationRepository findCareLocationRepository(Ref ref) {
  return FindCareLocationRepositoryImpl();
}
