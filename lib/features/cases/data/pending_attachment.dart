import 'package:vcare_admin/features/home/data/home_models.dart';

enum PendingAttachmentStatus { uploading, done, error }

class PendingAttachment {
  const PendingAttachment({
    required this.id,
    required this.name,
    required this.dataUrl,
    required this.size,
    this.status = PendingAttachmentStatus.uploading,
    this.progress = 0,
    this.error,
  });

  final String id;
  final String name;
  final String dataUrl;
  final int size;
  final PendingAttachmentStatus status;
  final double progress;
  final String? error;

  PendingAttachment copyWith({
    PendingAttachmentStatus? status,
    double? progress,
    String? error,
    bool clearError = false,
  }) {
    return PendingAttachment(
      id: id,
      name: name,
      dataUrl: dataUrl,
      size: size,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
    );
  }

  RequestAttachment toAttachment() =>
      RequestAttachment(id: id, name: name, dataUrl: dataUrl, size: size);
}
