class RemoteConfigAppUpdateInfo {
  const RemoteConfigAppUpdateInfo({
    this.latestVersion,
    this.versionsForForceUpdate = const [],
    this.currentVersion,
    this.releaseNotes,
    this.releaseDate,
  });

  final String? latestVersion;
  final List<String> versionsForForceUpdate;
  final String? currentVersion;
  final String? releaseNotes;
  final String? releaseDate;

  bool get isUpdateAvailable =>
      _isUpdateAvailable(currentVersion, latestVersion);

  bool get isForceUpdate => versionsForForceUpdate.contains(currentVersion);

  RemoteConfigAppUpdateInfo copyWith({
    String? latestVersion,
    List<String>? versionsForForceUpdate,
    String? currentVersion,
    String? releaseNotes,
    String? releaseDate,
  }) {
    return RemoteConfigAppUpdateInfo(
      latestVersion: latestVersion ?? this.latestVersion,
      versionsForForceUpdate:
          versionsForForceUpdate ?? this.versionsForForceUpdate,
      currentVersion: currentVersion ?? this.currentVersion,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }

  /// Returns true if [latest] is strictly newer than [current].
  static bool _isUpdateAvailable(String? current, String? latest) {
    if (current == null || latest == null) return false;

    final a = latest.trim().split('.').map(_safeParsePart).toList();
    final b = current.trim().split('.').map(_safeParsePart).toList();

    final maxLength = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < maxLength; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;

      if (av > bv) return true;
      if (av < bv) return false;
    }

    return false;
  }

  static int _safeParsePart(String part) {
    final numeric = RegExp(r'^\d+').stringMatch(part);
    return numeric != null ? int.parse(numeric) : 0;
  }
}
