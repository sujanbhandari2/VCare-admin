import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';
import 'package:vcare_admin/features/feature_access/domain/repositories/feature_access_repository.dart';
import 'package:vcare_admin/features/feature_access/presentation/providers/feature_access_repository_provider.dart';

class FakeFeatureAccessRepository implements FeatureAccessRepository {
  FakeFeatureAccessRepository(this.access);

  FeatureAccess access;
  EitherResponseOrException<FeatureAccess>? nextResult;
  var callCount = 0;

  @override
  Future<EitherResponseOrException<FeatureAccess>> fetchFeatureAccess({
    bool forceRefresh = false,
  }) async {
    callCount++;
    return nextResult ?? Success(access);
  }
}

fakeFeatureAccessRepositoryOverride(FeatureAccess access) {
  return featureAccessRepositoryProvider.overrideWithValue(
    FakeFeatureAccessRepository(access),
  );
}
