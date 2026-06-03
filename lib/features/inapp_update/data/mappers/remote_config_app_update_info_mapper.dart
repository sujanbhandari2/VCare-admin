import 'dart:io';

import '../../domain/entities/remote_config_app_update_info.dart';
import '../models/remote_config_app_update_info_model.dart';

extension RemoteConfigAppUpdateInfoModelX on RemoteConfigAppUpdateInfoModel {
  RemoteConfigAppUpdateInfo toEntity({String? currentVersion}) {
    final info = Platform.isIOS
        ? iosInfo
        : Platform.isAndroid
        ? androidInfo
        : null;

    return RemoteConfigAppUpdateInfo(
      latestVersion: info?.latestVersion,
      versionsForForceUpdate: info?.versionsForForceUpdate ?? [],
      releaseNotes: info?.releaseNotes,
      releaseDate: info?.releaseDate,
      currentVersion: currentVersion,
    );
  }
}
