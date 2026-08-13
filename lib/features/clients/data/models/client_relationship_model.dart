/// Relationship row from `GET /clients/:id/relationships`.
class ClientRelationshipModel {
  const ClientRelationshipModel({
    required this.id,
    this.clientId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.companyName,
    this.relationship,
    this.profilePreviewLink,
  });

  final String id;
  final String? clientId;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? companyName;
  final String? relationship;
  final String? profilePreviewLink;

  factory ClientRelationshipModel.fromJson(Map<String, dynamic> json) {
    return ClientRelationshipModel(
      id: json['id']?.toString() ?? json['clientId']?.toString() ?? '',
      clientId: json['clientId']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      companyName: json['companyName']?.toString(),
      relationship: json['relationship']?.toString(),
      profilePreviewLink: json['profilePreviewLink']?.toString(),
    );
  }
}
