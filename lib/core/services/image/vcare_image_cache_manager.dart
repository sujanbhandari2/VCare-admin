import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// App-wide disk cache for remote images loaded via [VCareCachedImage].
///
/// Extends [CacheManager] with [ImageCacheManager] so
/// `maxWidthDiskCache` / `maxHeightDiskCache` work. A custom file service
/// also enforces a minimum cache lifetime so short-lived S3
/// `Cache-Control` headers do not force constant re-downloads of signed URLs.
class VCareImageCacheManager extends CacheManager with ImageCacheManager {
  VCareImageCacheManager._()
      : super(
          Config(
            _cacheKey,
            stalePeriod: _stalePeriod,
            maxNrOfCacheObjects: 500,
            fileService: _VCareImageFileService(
              minCacheDuration: _stalePeriod,
            ),
          ),
        );

  static const String _cacheKey = 'vcareImageCache';
  static const Duration _stalePeriod = Duration(days: 30);

  static VCareImageCacheManager? _instance;

  static VCareImageCacheManager get instance {
    return _instance ??= VCareImageCacheManager._();
  }

  /// Removes all cached image files from disk.
  ///
  /// No-op when no images have been cached yet. Failures are swallowed.
  static Future<void> clearCache() async {
    final manager = _instance;
    if (manager == null) return;

    try {
      await manager.emptyCache();
    } catch (_) {}
  }
}

/// Ensures cached images stay valid for at least [minCacheDuration], even when
/// the origin sends `Cache-Control: no-cache` or a very short `max-age`.
class _VCareImageFileService extends HttpFileService {
  _VCareImageFileService({required this.minCacheDuration});

  final Duration minCacheDuration;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await super.get(url, headers: headers);
    return _MinAgeFileServiceResponse(
      response,
      minCacheDuration: minCacheDuration,
    );
  }
}

class _MinAgeFileServiceResponse implements FileServiceResponse {
  _MinAgeFileServiceResponse(
    this._inner, {
    required Duration minCacheDuration,
  }) : _minValidTill = DateTime.now().add(minCacheDuration);

  final FileServiceResponse _inner;
  final DateTime _minValidTill;

  @override
  int get statusCode => _inner.statusCode;

  @override
  Stream<List<int>> get content => _inner.content;

  @override
  int? get contentLength => _inner.contentLength;

  @override
  DateTime get validTill {
    final fromHeaders = _inner.validTill;
    return fromHeaders.isAfter(_minValidTill) ? fromHeaders : _minValidTill;
  }

  @override
  String? get eTag => _inner.eTag;

  @override
  String get fileExtension => _inner.fileExtension;
}
