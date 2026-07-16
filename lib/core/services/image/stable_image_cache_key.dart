/// Builds a stable cache key for remote images whose signed URLs rotate.
///
/// Prefer [storagePath] (e.g. `profileImage`) because it changes when the
/// underlying file changes. Fall back to the URL path without query params,
/// then to [entityId].
String? stableImageCacheKey({
  required String prefix,
  String? entityId,
  String? storagePath,
  String? imageUrl,
}) {
  final trimmedStorage = storagePath?.trim();
  if (trimmedStorage != null && trimmedStorage.isNotEmpty) {
    return '$prefix:$trimmedStorage';
  }

  final trimmedUrl = imageUrl?.trim();
  if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
    final pathKey = _urlPathWithoutQuery(trimmedUrl);
    if (pathKey.isNotEmpty) {
      return '$prefix:$pathKey';
    }
  }

  final trimmedId = entityId?.trim();
  if (trimmedId != null && trimmedId.isNotEmpty) {
    return '$prefix:$trimmedId';
  }

  return null;
}

String _urlPathWithoutQuery(String url) {
  try {
    final uri = Uri.parse(url);
    if (uri.hasScheme) {
      return '${uri.host}${uri.path}';
    }
  } catch (_) {}

  return url.split('?').first;
}
