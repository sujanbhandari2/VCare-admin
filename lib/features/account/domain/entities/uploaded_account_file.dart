/// File returned by `POST /files` when uploading an account profile photo.
class UploadedAccountFile {
  const UploadedAccountFile({
    required this.id,
    this.url,
  });

  final String id;
  final String? url;
}
