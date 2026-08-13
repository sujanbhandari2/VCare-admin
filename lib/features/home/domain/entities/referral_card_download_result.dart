class ReferralCardDownloadResult {
  const ReferralCardDownloadResult({
    required this.success,
    this.fileName,
  });

  final bool success;
  final String? fileName;
}
