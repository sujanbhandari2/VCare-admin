import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/remote_config_app_update_repository_impl.dart';
import '../../domain/repositories/remote_config_app_update_repository.dart';

part 'remote_config_app_update_repository_provider.g.dart';

@Riverpod(keepAlive: true)
RemoteConfigAppUpdateRepository remoteConfigAppUpdateInfoRepository(Ref ref) {
  return const RemoteConfigAppUpdateRepositoryImpl();
}
