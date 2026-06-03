import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

/// Represents a single file field for multipart requests.
class FormFile {
  FormFile._({required this.key, this.filePath, this.bytes, this.fileName});

  /// Creates a multipart file from a local file path.
  factory FormFile.fromPath({
    required String fieldName,
    required String filePath,
    String? fileName,
  }) {
    return FormFile._(key: fieldName, filePath: filePath, fileName: fileName);
  }

  /// Creates a multipart file from memory bytes.
  factory FormFile.fromBytes({
    required String fieldName,
    required List<int> bytes,
    required String fileName,
  }) {
    return FormFile._(key: fieldName, bytes: bytes, fileName: fileName);
  }

  /// Backward-compatible constructor used by existing call sites.
  factory FormFile({required String? fieldName, required String? path}) {
    if (fieldName == null || fieldName.trim().isEmpty) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        'fieldName is required',
      );
    }
    if (path == null || path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'path is required');
    }

    return FormFile.fromPath(fieldName: fieldName, filePath: path);
  }

  final String key;
  final String? filePath;
  final List<int>? bytes;
  final String? fileName;

  bool get hasPath => filePath != null && filePath!.trim().isNotEmpty;
  bool get hasBytes => bytes != null;

  Future<MultipartFile> toMultipartFile() async {
    if (hasPath) {
      final resolvedFileName = fileName ?? path.basename(filePath!.trim());
      return MultipartFile.fromFile(
        filePath!.trim(),
        filename: resolvedFileName,
      );
    }

    if (hasBytes) {
      final resolvedFileName = fileName ?? 'upload.bin';
      return MultipartFile.fromBytes(bytes!, filename: resolvedFileName);
    }

    throw ArgumentError('Either filePath or bytes must be provided.');
  }
}
