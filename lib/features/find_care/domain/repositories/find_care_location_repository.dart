import 'package:vcare_admin/features/find_care/domain/entities/current_location_result.dart';

abstract class FindCareLocationRepository {
  Future<bool> hasPermission();

  /// Resolves the device location into a city/state [SearchLocation].
  ///
  /// When [requestPermission] is true, prompts for location service/permission
  /// if needed. When false, fails immediately if permission is missing.
  Future<CurrentLocationResult> detectCurrentLocation({
    bool requestPermission = true,
  });
}
