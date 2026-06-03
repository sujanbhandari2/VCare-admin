class RemoteConfigAppUpdateInfoModel {
  const RemoteConfigAppUpdateInfoModel({this.iosInfo, this.androidInfo});

  final AppUpdateInfoModel? iosInfo;
  final AppUpdateInfoModel? androidInfo;

  factory RemoteConfigAppUpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return RemoteConfigAppUpdateInfoModel(
      iosInfo: json['ios'] != null
          ? AppUpdateInfoModel.fromJson(json['ios'])
          : null,
      androidInfo: json['android'] != null
          ? AppUpdateInfoModel.fromJson(json['android'])
          : null,
    );
  }
}

class AppUpdateInfoModel {
  const AppUpdateInfoModel({
    this.latestVersion,
    this.versionsForForceUpdate = const [],
    this.releaseNotes,
    this.releaseDate,
  });

  final String? latestVersion;
  final List<String> versionsForForceUpdate;
  final String? releaseNotes;
  final String? releaseDate;

  factory AppUpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfoModel(
      latestVersion: json['latest_version']?.toString(),
      versionsForForceUpdate: json['versions_for_force_update'] is String
          ? json['versions_for_force_update'].toString().split(", ")
          : json['versions_for_force_update'] is List
          ? (json['versions_for_force_update'] as List)
                .map((e) => e is String ? e.toString() : null)
                .nonNulls
                .toList()
          : [],
      releaseNotes: json['release_notes']?.toString(),
      releaseDate: json['release_date']?.toString(),
    );
  }
}
