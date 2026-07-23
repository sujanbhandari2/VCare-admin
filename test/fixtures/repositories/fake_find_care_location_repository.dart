import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';
import 'package:vcare_admin/features/find_care/domain/repositories/find_care_location_repository.dart';

class FakeFindCareLocationRepository implements FindCareLocationRepository {
  bool hasPermissionValue = false;
  CurrentLocationResult detectResult = const CurrentLocationFailure(
    reason: CurrentLocationFailureReason.permissionDenied,
  );

  int hasPermissionCallCount = 0;
  int detectCallCount = 0;
  bool? lastRequestPermission;

  @override
  Future<bool> hasPermission() async {
    hasPermissionCallCount += 1;
    return hasPermissionValue;
  }

  @override
  Future<CurrentLocationResult> detectCurrentLocation({
    bool requestPermission = true,
  }) async {
    detectCallCount += 1;
    lastRequestPermission = requestPermission;
    return detectResult;
  }
}
