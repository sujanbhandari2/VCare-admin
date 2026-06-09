import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/services/firebase/firebase_remote_config_service.dart';
import '../../../../core/services/network/typedefs/response_or_exception.dart';
import '../../domain/entities/remote_config_app_update_info.dart';
import '../../domain/repositories/remote_config_app_update_repository.dart';
import '../mappers/remote_config_app_update_info_mapper.dart';
import '../models/remote_config_app_update_info_model.dart';

class RemoteConfigAppUpdateRepositoryImpl
    implements RemoteConfigAppUpdateRepository {
  const RemoteConfigAppUpdateRepositoryImpl();

  @override
  Future<EitherResponseOrException<RemoteConfigAppUpdateInfo>>
  fetchRemoteConfigUpdateInfo() {
    return safeNetworkCall(() async {
      final packageInfo = await PackageInfo.fromPlatform();

      final configJsonStr = await FirebaseRemoteConfigService.instance
          .get<String>('flutter_template_config');

      final configJson = configJsonStr != null
          ? jsonDecode(configJsonStr)
          : <String, dynamic>{};

      final updateInfoModel = RemoteConfigAppUpdateInfoModel.fromJson(
        configJson['update_config'],
      );

      return updateInfoModel.toEntity(currentVersion: packageInfo.version);
    });
  }
}
