import 'package:vcare_admin/core/services/network/typedefs/response_or_exception.dart';
import 'package:vcare_admin/features/feature_access/domain/entities/feature_access.dart';

abstract class FeatureAccessRepository {
  Future<EitherResponseOrException<FeatureAccess>> fetchFeatureAccess({
    bool forceRefresh = false,
  });
}
