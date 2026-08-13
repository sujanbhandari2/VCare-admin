/// A file attached to a referral case.
class CaseFile {
  const CaseFile({
    required this.id,
    required this.name,
    required this.uploadedAt,
    this.type = '',
    this.size = '',
    this.uploadedBy = '',
    this.url,
  });

  final String id;
  final String name;
  final String type;
  final String size;
  final String uploadedAt;
  final String uploadedBy;
  final String? url;
}
