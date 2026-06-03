import '../../../../core/services/network/typedefs/response_or_exception.dart';
import '../entities/remote_config_app_update_info.dart';

/// Contract for fetching Remote Config Update information.
/// The implementation lives in data/repositories/.
abstract class RemoteConfigAppUpdateRepository {
  /// Returns [RemoteConfigAppUpdateInfo] for checking if newer version is available
  /// or already up to date.
  Future<EitherResponseOrException<RemoteConfigAppUpdateInfo>>
  fetchRemoteConfigUpdateInfo();
}
